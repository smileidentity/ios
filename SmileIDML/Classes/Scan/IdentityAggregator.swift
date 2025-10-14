class IdentityAggregator: ResultAggregator<AnalyzerInput, IdentityScanState, AnalyzerOutput, IdentityAggregator.InterimResult, IdentityAggregator.FinalResult> {
  struct InterimResult {
    // Define interim result properties
  }

  struct FinalResult {
    // Define final result properties
  }

  init(
    identityScanType _: IdentityScanState.ScanType,
    aggregateResultListener: some AggregateResultListener<InterimResult, FinalResult>
  ) {
    let initialState = IdentityScanState()
    super.init(listener: aggregateResultListener, initialState: initialState)
  }

  override func aggregateResult(
    frame _: AnalyzerInput,
    result _: AnalyzerOutput
  ) async -> (InterimResult, FinalResult?) {
    // Implement aggregation logic
    let interim = InterimResult()
    return (interim, nil)
  }
}

extension IdentityScanState {
  init() {
    // Initialize with default values
  }
}
