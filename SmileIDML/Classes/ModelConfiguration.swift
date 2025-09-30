import Foundation

struct ModelConfiguration {
  // Face Detection
  var faceDetectionProvider: ModelProviderType = .vision
  var minFaceSize: CGFloat = 0.15 // 15% of frame
  var maxFaceSize: CGFloat = 0.80 // 80% of frame
  var facePositionTolenrance: CGFloat = 0.1 // Distance from center

  // Liveness
  var livenessProvider: ModelProviderType = .vision
  var livenessTimeout: TimeInterval = 10.0
  var smileThreshold: Float = 0.7
  var headposeThreshold: Float = 15.0 // Degrees

  // Quality
  var qualityProvider: ModelProviderType = .vision
  var minDocumentSharpness: Float = 0.7
  var glareDetectionEnabled: Bool = true

  // Performance
  var enableDebugVisualization: Bool = false
  var maxConcurrentRequests: Int = 2
  var modelCacheSize: Int = 3
}

enum ModelProviderType {
  case vision
  case coreml
  case mediapipe
}
