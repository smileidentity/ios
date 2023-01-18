import CoreVideo
import CoreImage
import UIKit
import VideoToolbox
import Accelerate
import Vision

extension Date {
    var millisecondsSince1970: Int64 {
        Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
}

func captureJPGImage(from buffer: CVPixelBuffer,
                     with size: CGSize,
                     and faceGeometry: FaceGeometryModel,
                     isGreyScale: Bool) -> Data? {
    CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags.readOnly)
    defer { CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags.readOnly)}
    guard let resizedBuffer = resizePixelBuffer(buffer, size: size) else {
        return nil
    }
    return cvImageBufferToJPG(imageBuffer: resizedBuffer, isGreyScale: isGreyScale)
}

func cvImageBufferToJPG(imageBuffer: CVImageBuffer, isGreyScale: Bool) -> Data? {
    var ciImage = CIImage(cvPixelBuffer: imageBuffer)
    if isGreyScale {
        let greyFilter = CIFilter(name: "CIPhotoEffectNoir")
        greyFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        ciImage = greyFilter?.outputImage ?? ciImage
    }
    let context = CIContext()
    let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
    let jpegData = UIImage(cgImage: cgImage!).jpegData(compressionQuality: 1.0)
    return jpegData
}

private func metalCompatiblityAttributes() -> [String: Any] {
  let attributes: [String: Any] = [
    String(kCVPixelBufferMetalCompatibilityKey): true,
    String(kCVPixelBufferOpenGLCompatibilityKey): true,
    String(kCVPixelBufferIOSurfacePropertiesKey): [
      String(kCVPixelBufferIOSurfaceOpenGLESTextureCompatibilityKey): true,
      String(kCVPixelBufferIOSurfaceOpenGLESFBOCompatibilityKey): true,
      String(kCVPixelBufferIOSurfaceCoreAnimationCompatibilityKey): true
    ]
  ]
  return attributes
}

/**
  Creates a pixel buffer of the specified width, height, and pixel format.
  - Note: This pixel buffer is backed by an IOSurface and therefore can be
    turned into a Metal texture.
*/
public func createPixelBuffer(width: Int, height: Int, pixelFormat: OSType) -> CVPixelBuffer? {
  let attributes = metalCompatiblityAttributes() as CFDictionary
  var pixelBuffer: CVPixelBuffer?
  let status = CVPixelBufferCreate(nil, width, height, pixelFormat, attributes, &pixelBuffer)
  if status != kCVReturnSuccess {
    print("Error: could not create pixel buffer", status)
    print("Error: could not create pixel buffer", status)
    return nil
  }
  return pixelBuffer
}

public func resizePixelBuffer(from srcPixelBuffer: CVPixelBuffer,
                              to dstPixelBuffer: CVPixelBuffer,
                              cropX: Int,
                              cropY: Int,
                              cropWidth: Int,
                              cropHeight: Int,
                              scaleWidth: Int,
                              scaleHeight: Int) {

  assert(CVPixelBufferGetWidth(dstPixelBuffer) >= scaleWidth)
  assert(CVPixelBufferGetHeight(dstPixelBuffer) >= scaleHeight)

  let srcFlags = CVPixelBufferLockFlags.readOnly
  let dstFlags = CVPixelBufferLockFlags(rawValue: 0)

  guard kCVReturnSuccess == CVPixelBufferLockBaseAddress(srcPixelBuffer, srcFlags) else {
    print("Error: could not lock source pixel buffer")
    print("Error: could not lock source pixel buffer")
    return
  }
  defer { CVPixelBufferUnlockBaseAddress(srcPixelBuffer, srcFlags) }

  guard kCVReturnSuccess == CVPixelBufferLockBaseAddress(dstPixelBuffer, dstFlags) else {
    print("Error: could not lock destination pixel buffer")
    print("Error: could not lock destination pixel buffer")
    return
  }
  defer { CVPixelBufferUnlockBaseAddress(dstPixelBuffer, dstFlags) }

  guard let srcData = CVPixelBufferGetBaseAddress(srcPixelBuffer),
        let dstData = CVPixelBufferGetBaseAddress(dstPixelBuffer) else {
    print("Error: could not get pixel buffer base address")
    print("Error: could not get pixel buffer base address")
    return
  }

  let srcBytesPerRow = CVPixelBufferGetBytesPerRow(srcPixelBuffer)
  let offset = cropY*srcBytesPerRow + cropX*4
  var srcBuffer = vImage_Buffer(data: srcData.advanced(by: offset),
                                height: vImagePixelCount(cropHeight),
                                width: vImagePixelCount(cropWidth),
                                rowBytes: srcBytesPerRow)

  let dstBytesPerRow = CVPixelBufferGetBytesPerRow(dstPixelBuffer)
  var dstBuffer = vImage_Buffer(data: dstData,
                                height: vImagePixelCount(scaleHeight),
                                width: vImagePixelCount(scaleWidth),
                                rowBytes: dstBytesPerRow)

  let error = vImageScale_ARGB8888(&srcBuffer, &dstBuffer, nil, vImage_Flags(0))
  if error != kvImageNoError {
    print("Error:", error)
    print("Error:", error)
  }
}

/**
  Resizes a CVPixelBuffer to a new width and height.
  This function requires the caller to pass in both the source and destination
  pixel buffers. The dimensions of destination pixel buffer should be at least
  `width` x `height` pixels.
*/
public func resizePixelBuffer(from srcPixelBuffer: CVPixelBuffer,
                              to dstPixelBuffer: CVPixelBuffer,
                              width: Int, height: Int) {
  resizePixelBuffer(from: srcPixelBuffer, to: dstPixelBuffer,
                    cropX: 0, cropY: 0,
                    cropWidth: CVPixelBufferGetWidth(srcPixelBuffer),
                    cropHeight: CVPixelBufferGetHeight(srcPixelBuffer),
                    scaleWidth: width, scaleHeight: height)
}

/**
  First crops the pixel buffer, then resizes it.
  This allocates a new destination pixel buffer that is Metal-compatible.
*/
public func resizePixelBuffer(_ srcPixelBuffer: CVPixelBuffer,
                              cropX: Int,
                              cropY: Int,
                              cropWidth: Int,
                              cropHeight: Int,
                              scaleWidth: Int,
                              scaleHeight: Int) -> CVPixelBuffer? {

  let pixelFormat = CVPixelBufferGetPixelFormatType(srcPixelBuffer)
  let dstPixelBuffer = createPixelBuffer(width: scaleWidth, height: scaleHeight,
                                         pixelFormat: pixelFormat)

  if let dstPixelBuffer = dstPixelBuffer {
    CVBufferPropagateAttachments(srcPixelBuffer, dstPixelBuffer)

    resizePixelBuffer(from: srcPixelBuffer, to: dstPixelBuffer,
                      cropX: cropX, cropY: cropY,
                      cropWidth: cropWidth, cropHeight: cropHeight,
                      scaleWidth: scaleWidth, scaleHeight: scaleHeight)
  }

  return dstPixelBuffer
}

/**
  Resizes a CVPixelBuffer to a new width and height.
  This allocates a new destination pixel buffer that is Metal-compatible.
*/
public func resizePixelBuffer(_ pixelBuffer: CVPixelBuffer,
                              size: CGSize) -> CVPixelBuffer? {

        let imageWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let imageHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
  return resizePixelBuffer(pixelBuffer, cropX: 0, cropY: 0,
                           cropWidth: Int(imageWidth),
                           cropHeight: Int(imageHeight),
                           scaleWidth: Int(size.width), scaleHeight: Int(size.height))
}
