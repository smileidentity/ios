import CoreVideo
import Foundation

protocol DocumentDetecting {
  func detectDocument(
    in buffer: CVPixelBuffer
  ) async throws -> DocumentDetectionResult
}
