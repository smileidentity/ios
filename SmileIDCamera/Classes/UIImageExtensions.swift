import AVFoundation
import UIKit

extension UIImage {
  func pixelBufferSampleBuffer() -> CMSampleBuffer? {
    guard let pixelBuffer = convertToPixelBuffer() else { return nil }

    var sampleBuffer: CMSampleBuffer?
    var formatDescription: CMFormatDescription?
    CMVideoFormatDescriptionCreateForImageBuffer(
      allocator: kCFAllocatorDefault,
      imageBuffer: pixelBuffer,
      formatDescriptionOut: &formatDescription
    )

    var timing = CMSampleTimingInfo.invalid
    guard let description = formatDescription else { return nil }
    CMSampleBufferCreateForImageBuffer(
      allocator: kCFAllocatorDefault,
      imageBuffer: pixelBuffer,
      dataReady: true,
      makeDataReadyCallback: nil,
      refcon: nil,
      formatDescription: description,
      sampleTiming: &timing,
      sampleBufferOut: &sampleBuffer
    )
    return sampleBuffer
  }

  func convertToPixelBuffer() -> CVPixelBuffer? {
    let attributes =
      [
        kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue!,
        kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue!
      ] as CFDictionary

    var pixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(
      kCFAllocatorDefault,
      Int(size.width),
      Int(size.height),
      kCVPixelFormatType_32ARGB,
      attributes,
      &pixelBuffer
    )
    guard status == kCVReturnSuccess,
          let pixelBuffer
    else { return nil }

    CVPixelBufferLockBaseAddress(pixelBuffer, [])
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

    guard
      let context = CGContext(
        data: CVPixelBufferGetBaseAddress(pixelBuffer),
        width: Int(size.width),
        height: Int(size.height),
        bitsPerComponent: 8,
        bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
      )
    else {
      return nil
    }

    context.translateBy(x: 0, y: size.height)
    context.scaleBy(x: 1.0, y: -1.0)
    UIGraphicsPushContext(context)
    draw(in: CGRect(origin: .zero, size: size))
    UIGraphicsPopContext()

    return pixelBuffer
  }
}
