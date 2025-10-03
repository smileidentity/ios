import CoreVideo
import Foundation

protocol FaceDetecting {
  func detectFaces(
    in buffer: CVPixelBuffer
  ) async throws -> [FaceDetectionResult]
}
