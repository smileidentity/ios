import Foundation
import Vision

protocol CaptureStoreType {
  var livenessURLs: [URL] { get }
  var selfieURL: URL? { get }
  func saveLiveness(
    _ buffer: CVPixelBuffer,
    orientation: CGImagePropertyOrientation
  ) throws
  func saveSelfie(
    _ buffer: CVPixelBuffer,
    orientation: CGImagePropertyOrientation
  ) throws
  func reset() throws
}

final class CaptureStore: CaptureStoreType {
  private(set) var livenessURLs: [URL] = []
  private(set) var selfieURL: URL?

  private let jobId: String
  private static let livenessImageSize: Int = 320
  private static let selfieImageSize: Int = 640

  init(
    jobId: String
  ) {
    self.jobId = jobId
  }

  func saveLiveness(
    _ buffer: CVPixelBuffer,
    orientation: CGImagePropertyOrientation
  ) throws {
    guard let data = ImageUtils.resizePixelBufferToHeight(
      buffer,
      height: Self.livenessImageSize,
      orientation: orientation
    ) else {
      throw SmileIDError.unknown("Resize liveness failed")
    }

    let url = try LocalStorage.createLivenessFile(jobId: jobId, livenessFile: data)
    livenessURLs.append(url)
  }

  func saveSelfie(
    _ buffer: CVPixelBuffer,
    orientation _: CGImagePropertyOrientation
  ) throws {
    guard let data = ImageUtils.resizePixelBufferToHeight(
      buffer,
      height: Self.selfieImageSize
    ) else {
      throw SmileIDError.unknown("Resize liveness failed")
    }

    selfieURL = try LocalStorage.createSelfieFile(
      jobId: jobId,
      selfieFile: data
    )
  }

  func reset() throws {
    try LocalStorage.deleteLivenessAndSelfieFiles(at: [jobId])
    livenessURLs.removeAll()
    selfieURL = nil
  }
}
