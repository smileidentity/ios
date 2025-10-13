/**
 * Interface to determine how to transition between IdentityScanStates.
 */
protocol IdentityScanStateTransitioner {
  func transitionFromInitial(
    initialState: IdentityScanState,
    analyzerInput: AnalyzerInput,
    analyzerOutput: AnalyzerOutput
  ) async -> IdentityScanState

  func transitionFromFound(
    foundState: IdentityScanState,
    analyzerInput: AnalyzerInput,
    analyzerOutput: AnalyzerOutput
  ) async -> IdentityScanState

  func transitionFromSatisfied(
    satisfiedState: IdentityScanState,
    analyzerInput: AnalyzerInput,
    analyzerOutput: AnalyzerOutput
  ) async -> IdentityScanState

  func transitionFromUnsatisfied(
    unsatisfiedState: IdentityScanState,
    analyzerInput: AnalyzerInput,
    analyzerOutput: AnalyzerOutput
  ) async -> IdentityScanState
}
