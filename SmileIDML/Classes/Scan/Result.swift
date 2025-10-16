import Foundation

/// A result handler for data processing. This is called when results are available from an Analyzer.
protocol ResultHandler {
  associatedtype Input
  associatedtype Output
  associatedtype Verdict

  func onResult(result: Output, data: Input) async throws -> Verdict
}

/// A specialized result handler that has some form of state.
class StatefulResultHandler<Input, State, Output, Verdict>: ResultHandler {
  private let initialState: State

  /// The state of the result handler. This can be read, but not updated by analyzers.
  var state: State {
    get { _state }
    set { _state = newValue }
  }

  private var _state: State

  init(initialState: State) {
    self.initialState = initialState
    self._state = initialState
  }

  /// Reset the state to the initial value.
  func reset() {
    _state = initialState
  }

  func onResult(result _: Output, data _: Input) async -> Verdict {
    fatalError("Must be implemented by subclass")
  }
}

protocol AggregateResultListener<InterimResult, FinalResult> {
  associatedtype InterimResult
  associatedtype FinalResult

  /// The aggregated result of an AnalyzerLoop is available.
  func onResult(result: FinalResult) /// An interim result is available, but the AnalyzerLoop is still processing more data frames.
    /// This is useful for displaying a debug window or handling state updates during a scan.
    async

  func onInterimResult(result: InterimResult) /// The result aggregator was reset back to its original state.
    async

  func onReset() async
}

/// The ResultAggregator processes results from analyzers until a condition is met.
/// That condition is part of the aggregator's logic.
class ResultAggregator<DataFrame, State, AnalyzerResult, InterimResult, FinalResult>:
  StatefulResultHandler<DataFrame, State, AnalyzerResult, Bool> {
  private let listener: any AggregateResultListener<InterimResult, FinalResult>
  private let initialStateValue: State

  // Async-safe serial executor for iOS 13+
  private let serialQueue = DispatchQueue(label: "com.smileidentity.resultAggregator")

  private var isCanceled = false
  private var isFinished = false

  init(listener: some AggregateResultListener<InterimResult, FinalResult>, initialState: State) {
    self.listener = listener
    self.initialStateValue = initialState
    super.init(initialState: initialState)
  }

  /// Cancel a result aggregator. This means that the result aggregator will ignore all further
  /// results and will never return a final result.
  func cancel() {
    reset()
    isCanceled = true
  }

  /// Reset the state of the aggregator. This is useful for aggregating data that can become
  /// invalid, such as when a user is scanning an object, and moves the object away from the camera
  /// before the scan has completed.
  override func reset() {
    super.reset()
    isCanceled = false
    isFinished = false
    state = initialStateValue

    Task {
      await listener.onReset()
    }
  }

  override func onResult(result: AnalyzerResult, data: DataFrame) async -> Bool {
    guard !isCanceled, !isFinished else { return true }

    let (interimResult, finalResult) = await aggregateResult(frame: data, result: result)

    await listener.onInterimResult(result: interimResult)

    if !isFinished, let finalResult {
      isFinished = true
      await listener.onResult(result: finalResult)
    }

    return isFinished
  }

  /// Aggregate a new result. If this method returns a non-null FinalResult, the aggregator will
  /// stop listening for new results.
  func aggregateResult(
    frame _: DataFrame,
    result _: AnalyzerResult
  ) async -> (InterimResult, FinalResult?) {
    fatalError("Must be implemented by subclass")
  }
}

class AnyAggregateResultListener<InterimResult, FinalResult>: AggregateResultListener {
  private let _onResult: (FinalResult) async -> Void
  private let _onInterimResult: (InterimResult) async -> Void
  private let _onReset: () async -> Void

  init<L: AggregateResultListener>(_ listener: L)
    where L.InterimResult == InterimResult, L.FinalResult == FinalResult {
    self._onResult = listener.onResult
    self._onInterimResult = listener.onInterimResult
    self._onReset = listener.onReset
  }

  func onResult(result: FinalResult) async {
    await _onResult(result)
  }

  func onInterimResult(result: InterimResult) async {
    await _onInterimResult(result)
  }

  func onReset() async {
    await _onReset()
  }
}
