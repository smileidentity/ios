import CoreVideo
import Foundation

protocol LivenessDetecting {
  func detectLiveness(
    in buffer: CVPixelBuffer,
    previousResults: [LivenessDetectionResult]
  ) async throws -> LivenessDetectionResult
}
