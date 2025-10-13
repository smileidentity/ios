/**
 * An analyzer takes some data as an input, and returns an analyzed output. Analyzers should not
 * contain any state. They must  provide a means of analyzing input data to return some form of result.
 */
protocol Analyzer {
  associatedtype Input
  associatedtype State
  associatedtype Output

  func analyze(data: Input, state: State) async -> Output
}

/**
 * A factory to create analyzers.
 */
protocol AnalyzerFactory {
  associatedtype Input
  associatedtype State
  associatedtype Output
  associatedtype AnalyzerType: Analyzer where
    AnalyzerType.Input == Input,
    AnalyzerType.State == State,
    AnalyzerType.Output == Output

  func newInstance() async -> AnalyzerType?
}
