import CoreMedia
import Foundation
import ImageIO

public struct CameraExifMetadata: Equatable {
  public let brightnessValue: Double?
  public let focalLength: Double?
  public let lensModel: String?
}

public struct CameraMetadataExtractor {
  public init() {}

  public func metadata(
    from sampleBuffer: CMSampleBuffer
  ) -> CameraExifMetadata? {
    guard let attachments = CMGetAttachment(
      sampleBuffer,
      key: kCGImagePropertyExifDictionary,
      attachmentModeOut: nil
    ) as? [CFString: Any] else {
      return nil
    }

    return CameraExifMetadata(
      brightnessValue: attachments[kCGImagePropertyExifBrightnessValue] as? Double,
      focalLength: attachments[kCGImagePropertyExifFocalLength] as? Double,
      lensModel: attachments[kCGImagePropertyExifLensModel] as? String
    )
  }
}
