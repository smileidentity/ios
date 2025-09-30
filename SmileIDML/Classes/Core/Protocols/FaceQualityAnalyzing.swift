import CoreVideo
import Foundation

protocol FaceQualityAnalyzing {
  func analyzeFaceQuality(
    in buffer: CVPixelBuffer,
    face: FaceDetectionResult
  ) async throws -> FaceQualityResult
}
