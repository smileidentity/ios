import Foundation

struct FaceDetectionResult {
  let boundingBox: CGRect // Normalized coordinates [0-1]
  let landmarks: FaceLandmarks?
  let trackingID: Int? // For tracking across frames
  let roll: Float?
  let pitch: Float?
  let yaw: Float?
  let confidence: Float // Detection confidence [0-1]
}
