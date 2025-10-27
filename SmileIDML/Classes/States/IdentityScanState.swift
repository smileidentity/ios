/**
 * States during scanning a document.
 */
enum IdentityScanState {
  /**
   * Initial state when scan starts, no documents have been detected yet.
   */
  case initial(type: ScanType, transitioner: IdentityScanStateTransitioner)

  /**
   * State when scan has found the required type, the machine could stay in this state for a
   * while if more image needs to be processed to reach the next state.
   */
  case found(type: ScanType, transitioner: IdentityScanStateTransitioner)

  /**
   * State when satisfaction checking passed.
   *
   * Note when Satisfied is reached, [timeoutAt] won't be checked.
   */
  case satisfied(type: ScanType, transitioner: IdentityScanStateTransitioner)

  /**
   * State when satisfaction checking failed.
   */
  case unsatisfied(type: ScanType, transitioner: IdentityScanStateTransitioner)

  /**
   * Terminal state, indicating the scan is finished.
   */
  case finished(type: ScanType, transitioner: IdentityScanStateTransitioner)

  /**
   * Terminal state, indicating the scan times out.
   */
  case timeOut(type: ScanType, transitioner: IdentityScanStateTransitioner)

  /**
   * Type of documents being scanned
   */
  enum ScanType {
    case document
    case selfie
  }

  // MARK: - Computed Properties

  var type: ScanType {
    switch self {
    case .initial(let type, _),
         .found(let type, _),
         .satisfied(let type, _),
         .unsatisfied(let type, _),
         .finished(let type, _),
         .timeOut(let type, _):
      return type
    }
  }

  var transitioner: IdentityScanStateTransitioner {
    switch self {
    case .initial(_, let transitioner),
         .found(_, let transitioner),
         .satisfied(_, let transitioner),
         .unsatisfied(_, let transitioner),
         .finished(_, let transitioner),
         .timeOut(_, let transitioner):
      return transitioner
    }
  }

  // MARK: - State Transitions

  /**
   * Transitions to the next state based on model output.
   */
  func consumeTransition(
    analyzerInput: AnalyzerInput,
    analyzerOutput: AnalyzerOutput
  ) async -> IdentityScanState {
    switch self {
    case .initial:
      return await transitioner.transitionFromInitial(
        initialState: self,
        analyzerInput: analyzerInput,
        analyzerOutput: analyzerOutput
      )

    case .found:
      return await transitioner.transitionFromFound(
        foundState: self,
        analyzerInput: analyzerInput,
        analyzerOutput: analyzerOutput
      )

    case .satisfied:
      return await transitioner.transitionFromSatisfied(
        satisfiedState: self,
        analyzerInput: analyzerInput,
        analyzerOutput: analyzerOutput
      )

    case .unsatisfied:
      return await transitioner.transitionFromUnsatisfied(
        unsatisfiedState: self,
        analyzerInput: analyzerInput,
        analyzerOutput: analyzerOutput
      )

    case .finished, .timeOut:
      // Terminal states, no transition
      return self
    }
  }
}
