import CoreGraphics
import Foundation

/**
 * [IdentityScanStateTransitioner] for FaceDetector model.
 *
 * To transition from [com.smileidentity.ml.states.IdentityScanState.Initial] state -
 * * Check if it's timeout since the start of the scan.
 * * Check if a valid face is present, see [isFaceValid] for details. Save the frame and transition to Found if so.
 * * Otherwise stay in [IdentityScanState.Initial]
 *
 * To transition from [IdentityScanState.Found] state -
 * * Check if it's timeout since the start of the scan.
 * * Wait for an interval between two Found state, if the interval is not reached, keep waiting.
 * * Check if a valid face is present, save the frame and check if enough frames have been collected
 *  * If so, transition to [IdentityScanState.Satisfied]
 *  * Otherwise check how long it's been since the last transition to [IdentityScanState.Found]
 *  *   If it's within [stayInFoundDuration], stay in [IdentityScanState.Found]
 *  *   Otherwise transition to [IdentityScanState.Unsatisfied]
 *
 * To transition from [IdentityScanState.Satisfied] state -
 * * Directly transitions to [IdentityScanState.Finished]
 *
 * To transition from [IdentityScanState.Unsatisfied] state -
 * * Directly transitions to [IdentityScanState.Initial]
 */
class FaceDetectorTransitioner: IdentityScanStateTransitioner {
  private let selfieCaptureTimeout: Int
  private let numSamples: Int
  private let sampleInterval: Int
  private let faceDetectorMinScore: Float
  private let minEdgeThreshold: Float
  private let maxCoverageThreshold: Float
  private let minCoverageThreshold: Float
  private let maxCenteredThresholdY: Float
  private let maxCenteredThresholdX: Float
  let selfieFrameSaver: SelfieFrameSaver
  private let stayInFoundDuration: Int

  var timeoutAt: Date

  init(
    selfieCaptureTimeout: Int,
    numSamples: Int,
    sampleInterval: Int,
    faceDetectorMinScore: Float,
    minEdgeThreshold: Float,
    maxCoverageThreshold: Float,
    minCoverageThreshold: Float,
    maxCenteredThresholdY: Float,
    maxCenteredThresholdX: Float,
    selfieFrameSaver: SelfieFrameSaver = SelfieFrameSaver(),
    stayInFoundDuration: Int = Constants.defaultStayInFoundDuration
  ) {
    self.selfieCaptureTimeout = selfieCaptureTimeout
    self.numSamples = numSamples
    self.sampleInterval = sampleInterval
    self.faceDetectorMinScore = faceDetectorMinScore
    self.minEdgeThreshold = minEdgeThreshold
    self.maxCoverageThreshold = maxCoverageThreshold
    self.minCoverageThreshold = minCoverageThreshold
    self.maxCenteredThresholdY = maxCenteredThresholdY
    self.maxCenteredThresholdX = maxCenteredThresholdX
    self.selfieFrameSaver = selfieFrameSaver
    self.stayInFoundDuration = stayInFoundDuration
    self.timeoutAt = Date().addingTimeInterval(TimeInterval(selfieCaptureTimeout))
  }

  func resetAndReturn() -> FaceDetectorTransitioner {
    timeoutAt = Date().addingTimeInterval(TimeInterval(selfieCaptureTimeout))
    return self
  }

  var filteredFrames: [(AnalyzerInput, FaceDetectorOutput)] {
    guard let savedFrames = selfieFrameSaver.getSavedFrames()[Constants.selfies] else {
      preconditionFailure("No frames saved")
    }

    precondition(savedFrames.count >= Constants.numFilteredFrames,
                 "Not enough frames saved, frames saved: \(savedFrames.count)")

    let last = savedFrames.last!
    let best = savedFrames[1..<savedFrames.count - 1]
      .max(by: { $0.1.resultScore < $1.1.resultScore })!
    let first = savedFrames.first!

    return [last, best, first]
  }

  var numFrames: Int {
    numSamples
  }

  var bestFaceScore: Float {
    filteredFrames[Constants.indexBest].1.resultScore
  }

  var scoreVariance: Float {
    guard let savedFrames = selfieFrameSaver.getSavedFrames()[Constants.selfies] else {
      preconditionFailure("No frames saved")
    }

    precondition(savedFrames.count == numFrames,
                 "Not enough frames saved, score variance not calculated")

    let mean = savedFrames.reduce(0.0) { $0 + $1.1.resultScore } / Float(numFrames)

    let variance = savedFrames.reduce(0.0) { acc, pair in
      acc + pow(pair.1.resultScore - mean, 2)
    } / Float(numFrames)

    return sqrt(variance).rounded(toPlaces: 2)
  }

  // MARK: - State Transitions

  func transitionFromInitial(
    initialState: IdentityScanState,
    analyzerInput: AnalyzerInput,
    analyzerOutput: AnalyzerOutput
  ) async -> IdentityScanState {
    guard case .initial(let type, _) = initialState else {
      preconditionFailure("Expected initial state")
    }

    guard let faceOutput = analyzerOutput as? FaceDetectorOutput else {
      preconditionFailure("Unexpected output type: \(analyzerOutput)")
    }

    selfieFrameSaver.reset()

    if Date() >= timeoutAt {
      print("Timeout in Initial state: \(initialState)")
      return .timeOut(type: type, transitioner: self)
    }

    if isFaceValid(analyzerOutput: faceOutput) {
      print("Valid face found, transition to Found")
      selfieFrameSaver.saveFrame(
        frame: (analyzerInput, faceOutput),
        metaData: analyzerOutput
      )
      return .found(type: type, transitioner: self, reachedStateAt: Date())
    }

    print("Valid face not found, stay in Initial")
    return initialState
  }

  func transitionFromFound(
    foundState: IdentityScanState,
    analyzerInput: AnalyzerInput,
    analyzerOutput: AnalyzerOutput
  ) async -> IdentityScanState {
    guard case .found(let type, _, let reachedStateAt) = foundState else {
      preconditionFailure("Expected found state")
    }

    guard let faceOutput = analyzerOutput as? FaceDetectorOutput else {
      preconditionFailure("Unexpected output type: \(analyzerOutput)")
    }

    if Date() >= timeoutAt {
      print("Timeout in Found state: \(foundState)")
      return .timeOut(type: type, transitioner: self)
    }

    let elapsedTime = Date().timeIntervalSince(reachedStateAt)

    if elapsedTime < TimeInterval(sampleInterval) {
      print("Get a selfie before selfie capture interval, ignored. " +
        "Current selfieCollected: \(selfieFrameSaver.selfieCollected())")
      return foundState
    }

    if isFaceValid(analyzerOutput: faceOutput) {
      selfieFrameSaver.saveFrame(
        frame: (analyzerInput, faceOutput),
        metaData: analyzerOutput
      )

      if selfieFrameSaver.selfieCollected() >= numSamples {
        print("A valid selfie captured, enough selfie collected(\(numSamples)), transitions to Satisfied")
        return .satisfied(type: type, transitioner: self)
      } else {
        print("A valid selfie captured, need \(numSamples) selfies but has \(selfieFrameSaver.selfieCollected()), stays in Found")
        return .found(type: type, transitioner: self, reachedStateAt: Date())
      }
    }

    if elapsedTime < TimeInterval(stayInFoundDuration) / 1000.0 {
      print("Get an invalid selfie in Found state, but not enough time passed(\(elapsedTime)), stays in Found. " +
        "Current selfieCollected: \(selfieFrameSaver.selfieCollected())")
      return foundState
    }

    print("Didn't get a valid selfie in Found state after \(stayInFoundDuration) milliseconds, transition to Unsatisfied")
    return .unsatisfied(
      reason: "Didn't get a valid selfie in Found state after \(stayInFoundDuration) milliseconds",
      type: type,
      transitioner: self
    )
  }

  func transitionFromSatisfied(
    satisfiedState: IdentityScanState,
    analyzerInput _: AnalyzerInput,
    analyzerOutput _: AnalyzerOutput
  ) async -> IdentityScanState {
    guard case .satisfied(let type, _) = satisfiedState else {
      preconditionFailure("Expected satisfied state")
    }

    return .finished(type: type, transitioner: self)
  }

  func transitionFromUnsatisfied(
    unsatisfiedState: IdentityScanState,
    analyzerInput _: AnalyzerInput,
    analyzerOutput _: AnalyzerOutput
  ) async -> IdentityScanState {
    guard case .unsatisfied(_, let type, _) = unsatisfiedState else {
      preconditionFailure("Expected unsatisfied state")
    }

    return .initial(type: type, transitioner: resetAndReturn())
  }

  // MARK: - Validation Methods

  private func isFaceValid(analyzerOutput: FaceDetectorOutput) -> Bool {
    guard let firstFace = analyzerOutput.faces.first else {
      return false
    }

    return isNotMoreThanOneFace(analyzerOutput: analyzerOutput) &&
      isFaceCentered(boundingBox: firstFace.1) &&
      isFaceAwayFromEdges(boundingBox: firstFace.1) &&
      isFaceCoverageOK(boundingBox: firstFace.1) &&
      isFaceScoreOverThreshold(actualScore: analyzerOutput.resultScore)
  }

  private func isNotMoreThanOneFace(analyzerOutput: FaceDetectorOutput) -> Bool {
    analyzerOutput.faces.count <= 1
  }

  private func isFaceCentered(boundingBox: CGRect) -> Bool {
    let centerY = abs(1 - (boundingBox.minY + boundingBox.minY + boundingBox.height))
    let centerX = abs(1 - (boundingBox.minX + boundingBox.minX + boundingBox.width))

    return centerY < CGFloat(maxCenteredThresholdY) && centerX < CGFloat(maxCenteredThresholdX)
  }

  private func isFaceAwayFromEdges(boundingBox: CGRect) -> Bool {
    let threshold = CGFloat(minEdgeThreshold)
    return boundingBox.minY > threshold &&
      boundingBox.minX > threshold &&
      (boundingBox.minY + boundingBox.height) < (1 - threshold) &&
      (boundingBox.minX + boundingBox.width) < (1 - threshold)
  }

  private func isFaceCoverageOK(boundingBox: CGRect) -> Bool {
    let coverage = boundingBox.width * boundingBox.height
    return coverage < CGFloat(maxCoverageThreshold) && coverage > CGFloat(minCoverageThreshold)
  }

  private func isFaceScoreOverThreshold(actualScore: Float) -> Bool {
    actualScore > faceDetectorMinScore
  }

  class SelfieFrameSaver: FrameSaver<String, (AnalyzerInput, FaceDetectorOutput), AnalyzerOutput> {
    override func getMaxSavedFrames(savedFrameIdentifier _: String) -> Int {
      Int.max
    }

    override func getSaveFrameIdentifier(
      frame _: (AnalyzerInput, FaceDetectorOutput),
      metaData _: AnalyzerOutput
    ) -> String? {
      Constants.selfies
    }

    func selfieCollected() -> Int {
      getSavedFrames()[Constants.selfies]?.count ?? 0
    }
  }

  enum Selfie: String {
    case first
    case best
    case last

    var index: Int {
      switch self {
      case .first: return Constants.indexFirst
      case .best: return Constants.indexBest
      case .last: return Constants.indexLast
      }
    }
  }

  enum Constants {
    static let selfies = "SELFIES"
    static let numFilteredFrames = 3
    static let indexFirst = 0
    static let indexBest = 1
    static let indexLast = 2
    static let defaultStayInFoundDuration = 2000
  }
}
