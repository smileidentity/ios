import CoreVideo
import Foundation

protocol DocumentQualityAnalyzing {
  func analyzeDocumentQuality(
    in buffer: CVPixelBuffer,
    document: DocumentDetectionResult
  ) async throws -> DocumentQualityResult
}
