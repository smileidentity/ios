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

  func analyze(data: Input, state: State) async -> Output {
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
