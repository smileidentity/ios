import Foundation

struct FaceQualityResult {
  let overallQuality: Float // 0-1, higher is better
  let captureQuality: Float? // VNFaceObservation quality
  let sharpness: Float?
  let brightness: Float?
  let contrast: Float?
  let isEyesOpen: Bool?
  let hasGlasses: Bool?
  let hasObstructions: Bool?
  let meetsRequirements: Bool
  let failureReasons: [String]
}
