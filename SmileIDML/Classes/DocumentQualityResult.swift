import Foundation

struct DocumentQualityResult {
  let overallQuality: Float
  let sharpness: Float // Blur detection
  let hasGlare: Bool
  let glareRegions: [CGRect]
  let brightness: Float
  let meetsRequirements: Bool
  let failureReasons: [String]
}
