import Foundation

/// The default number of analyzers to run in parallel.
let defaultAnalyzerParallelCount = 2

// MARK: - Errors

enum AnalyzerError: Error {
  case noAnalyzersAvailable
  case alreadySubscribed
}

// MARK: - Protocol

protocol AnalyzerLoopErrorListener {
  /// A failure occurred during frame analysis. If this returns true, the loop will terminate. If
  /// this returns false, the loop will continue to execute on new data.
  func onAnalyzerFailure(_ error: Error) -> Bool

  /// A failure occurred while collecting the result of frame analysis. If this returns true, the
  /// loop will terminate. If this returns false, the loop will continue to execute on new data.
  func onResultFailure(_ error: Error) -> Bool
}

/// A source or destination of data that can be closed.
/// Equivalent to Java's Closeable interface.
protocol Closeable {
  /// Closes this resource and releases any system resources associated with it.
  /// If the resource is already closed then invoking this method has no effect.
  func close() throws
}

/// Type-erased wrapper for Analyzer (iOS 13 compatible)
/// when we move to iOS 16, we can remove this and use associated types
class AnyAnalyzer<Input, State, Output> {
  private let _analyze: (Input, State) async -> Output
  private let baseAnalyzer: Any

  init<A: Analyzer>(_ analyzer: A) where A.Input == Input, A.State == State, A.Output == Output {
    self._analyze = analyzer.analyze
    self.baseAnalyzer = analyzer
  }

  func analyze(data: Input, state: State) async throws -> Output {
    await _analyze(data, state)
  }

  func asCloseable() -> Closeable? {
    baseAnalyzer as? Closeable
  }
}

/// A pool of analyzers.
struct AnalyzerPool<DataFrame, State, Output> {
  let desiredAnalyzerCount: Int
  let analyzers: [AnyAnalyzer<DataFrame, State, Output>]

  static func of<Factory: AnalyzerFactory>(
    analyzerFactory: Factory,
    desiredAnalyzerCount: Int = defaultAnalyzerParallelCount
  ) async -> AnalyzerPool<DataFrame, State, Output>
    where Factory.Input == DataFrame,
    Factory.State == State,
    Factory.Output == Output {
    var analyzers: [AnyAnalyzer<DataFrame, State, Output>] = []

    for _ in 0..<desiredAnalyzerCount {
      if let analyzer = analyzerFactory.newInstance() {
        analyzers.append(AnyAnalyzer(analyzer))
      }
    }

    return AnalyzerPool(
      desiredAnalyzerCount: desiredAnalyzerCount,
      analyzers: analyzers
    )
  }

  func closeAllAnalyzers() {
    for analyzer in analyzers {
      if let closeable = analyzer.asCloseable() {
        try? closeable.close() // Suppresses errors, continues closing
      }
    }
  }
}

/// A loop to execute repeated analysis. The loop uses tasks to run the Analyzer.analyze method.
/// If the Analyzer is threadsafe, multiple tasks will be used. If not, a single task will be used.
///
/// Any data enqueued while the analyzers are at capacity will be dropped.
///
/// This will process data until the result aggregator returns true.
///
/// Note: an analyzer loop can only be started once. Once it terminates, it cannot be restarted.
class AnalyzerLoop<DataFrame, State, Output>: ResultHandler {
  typealias Input = DataFrame
  typealias Verdict = Bool

  private let analyzerPool: AnalyzerPool<DataFrame, State, Output>
  private let analyzerLoopErrorListener: AnalyzerLoopErrorListener

  private var started: Bool = false
  private var startedAt: Date?
  private var finished: Bool = false

  private var workerTask: Task<Void, Never>?

  init(
    analyzerPool: AnalyzerPool<DataFrame, State, Output>,
    analyzerLoopErrorListener: AnalyzerLoopErrorListener
  ) {
    self.analyzerPool = analyzerPool
    self.analyzerLoopErrorListener = analyzerLoopErrorListener
  }

  func subscribeToFlow(
    _ stream: AsyncStream<DataFrame>
  ) -> Task<Void, Never>? {
    // Check if already started
    if started {
      _ = analyzerLoopErrorListener.onAnalyzerFailure(AnalyzerError.alreadySubscribed)
      return nil
    }

    started = true
    startedAt = Date()

    if analyzerPool.analyzers.isEmpty {
      _ = analyzerLoopErrorListener.onAnalyzerFailure(AnalyzerError.noAnalyzersAvailable)
      return nil
    }

    workerTask = Task {
      await withTaskGroup(of: Void.self) { group in
        for analyzer in analyzerPool.analyzers {
          group.addTask {
            await self.startWorker(stream: stream, analyzer: analyzer)
          }
        }
      }
    }

    return workerTask
  }

  func unsubscribeFromFlow() async {
    workerTask?.cancel()
    workerTask = nil
    started = false
    finished = false
  }

  /// Launch a worker task that has access to the analyzer's analyze method and the result handler
  private func startWorker(
    stream: AsyncStream<DataFrame>,
    analyzer: AnyAnalyzer<DataFrame, State, Output>
  ) async {
    for await frame in stream {
      guard !Task.isCancelled else { break }

      do {
        let analyzerResult = try await analyzer.analyze(data: frame, state: getState())

        do {
          try finished = await onResult(result: analyzerResult, data: frame)
        } catch {
          await handleResultFailure(error)
        }
      } catch {
        await handleAnalyzerFailure(error)
      }

      if finished {
        await unsubscribeFromFlow()
        break
      }
    }
  }

  private func handleAnalyzerFailure(_ error: Error) async {
    let shouldTerminate = await MainActor.run {
      analyzerLoopErrorListener.onAnalyzerFailure(error)
    }

    if shouldTerminate {
      await unsubscribeFromFlow()
    }
  }

  private func handleResultFailure(_ error: Error) async {
    let shouldTerminate = await MainActor.run {
      analyzerLoopErrorListener.onResultFailure(error)
    }

    if shouldTerminate {
      await unsubscribeFromFlow()
    }
  }

  func getState() -> State {
    fatalError("Must be implemented by subclass")
  }

  func onResult(result _: Output, data _: DataFrame) async throws -> Bool {
    fatalError("Must be implemented by subclass")
  }
}

/// This kind of AnalyzerLoop will process data until the result handler indicates that it has
/// reached a terminal state and is no longer listening.
///
/// Data can be added to a queue for processing by a camera or other producer. It will be consumed by
/// FIFO. If no data is available, the analyzer pauses until data becomes available.
///
/// If the enqueued data exceeds the allowed memory size, the bottom of the data stack will be
/// dropped and will not be processed. This alleviates memory pressure when producers are faster than
/// the consuming analyzer.
class ProcessBoundAnalyzerLoop<DataFrame, State, Output>: AnalyzerLoop<DataFrame, State, Output> {
  private let resultHandler: StatefulResultHandler<DataFrame, State, Output, Bool>

  init(
    analyzerPool: AnalyzerPool<DataFrame, State, Output>,
    resultHandler: StatefulResultHandler<DataFrame, State, Output, Bool>,
    analyzerLoopErrorListener: AnalyzerLoopErrorListener
  ) {
    self.resultHandler = resultHandler
    super.init(
      analyzerPool: analyzerPool,
      analyzerLoopErrorListener: analyzerLoopErrorListener
    )
  }

  /// Subscribe to a stream. Loops can only subscribe to a single stream at a time.
  func subscribeTo(_ stream: AsyncStream<DataFrame>) -> Task<Void, Never>? {
    subscribeToFlow(stream)
  }

  /// Unsubscribe from the stream.
  func unsubscribe() {
    Task {
      await unsubscribeFromFlow()
    }
  }

  override func onResult(result: Output, data: DataFrame) async -> Bool {
    await resultHandler.onResult(result: result, data: data)
  }

  override func getState() -> State {
    resultHandler.state
  }
}
