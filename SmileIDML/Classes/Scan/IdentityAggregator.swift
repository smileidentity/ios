/// ResultAggregator for Identity.
///
/// Initialize the IdentityScanState.initial with corresponding
/// IdentityScanStateTransitioner based on IdentityScanState.ScanType.
class IdentityAggregator: ResultAggregator<AnalyzerInput, IdentityScanState, AnalyzerOutput, IdentityAggregator.InterimResult, IdentityAggregator.FinalResult> {
  private var isFirstResultReceived = false

  struct InterimResult {
    let identityState: IdentityScanState
  }

  struct FinalResult {
    let frame: AnalyzerInput
    let result: AnalyzerOutput
    let identityState: IdentityScanState
  }

  init(
    identityScanType: IdentityScanState.ScanType,
    aggregateResultListener: some AggregateResultListener<InterimResult, FinalResult>
  ) {
    let transitioner = FaceDetectorTransitioner(
      selfieCaptureTimeout: 10,
      numSamples: 5,
      sampleInterval: 2,
      faceDetectorMinScore: 0.0,
      minEdgeThreshold: 1.0,
      stayInFoundDuration: 1,
      maxCoverageThreshold: 1.0,
      minCoverageThreshold: 1.0,
      maxCenteredThresholdY: 1.0,
      maxCenteredThresholdX: 1.0
    )

    let initialState = IdentityScanState.initial(
      type: identityScanType,
      transitioner: transitioner
    )

    super.init(listener: aggregateResultListener, initialState: initialState)
  }

  override func aggregateResult(
    frame: AnalyzerInput,
    result: AnalyzerOutput
  ) async -> (InterimResult, FinalResult?) {
    if isFirstResultReceived {
      let previousState = state
      state = await previousState.consumeTransition(analyzerInput: frame, analyzerOutput: result)
      let interimResult = InterimResult(identityState: state)

      if state.isFinal {
        let finalResult = FinalResult(
          frame: frame,
          result: result,
          identityState: state
        )
        return (interimResult, finalResult)
      } else {
        return (interimResult, nil)
      }
    } else {
      // If this is the very first result, don't transition state and post InterimResult with
      // current state (IdentityScanState.initial).
      // This makes sure the receiver always receives IdentityScanState.initial as the first callback.
      isFirstResultReceived = true
      return (InterimResult(identityState: state), nil)
    }
  }
}
