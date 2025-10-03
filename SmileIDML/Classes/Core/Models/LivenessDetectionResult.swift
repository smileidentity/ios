import Foundation

struct LivenessDetectionResult {
  enum Status {
    case analyzing
    case passed
    case failed(reason: FailureReason)
  }

  enum FailureReason {
    case noFaceDetected
    case multipleFacesDetected
    case screenDetected // Anti-spoofing
    case photoDetected // Anti-spoofing
    case insufficientMovement
    case movementTooFast
    case timeout
  }

  let status: Status
  let confidence: Float
  let progress: Float // [0-1] for UI feedback
  let smileScore: Float? // For smile-base liveness
  let headPoseVariation: Float? // For pose-based liveness
  let timestamp: TimeInterval
}
