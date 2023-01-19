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
class ImageUtils {

    /// Converts a buffer to JPG cropping the  face and returning the result of this operation
    /// - Parameters:
    ///   - buffer: An input pixel buffer
    ///   - faceGeometry: A FaceGeometry object containing the frame of a detected face in the screens coordinate system
    ///   - finalSize: Final size of the cropped image
    ///   - screenImageSize: Size of the view the camera feed is displayed
    ///   - isGreyScale: A boolean flag, if true returns a greyscaled image
    /// - Returns: An optional JPG image data returned from the cropping and resizing operation
    class func captureFace(from buffer: CVPixelBuffer,
                               faceGeometry: FaceGeometryModel,
                               finalSize: CGSize,
                               screenImageSize: CGSize,
                               isGreyScale: Bool) -> Data? {

        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags.readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags.readOnly)}

        let padding: CGFloat = 60
        let faceCropWidthAndHeight = max(faceGeometry.boundingBox.size.height + padding,
                                         faceGeometry.boundingBox.size.width + padding)
        let cropY = faceGeometry.boundingBox.origin.y - (padding/2)
        let cropX = faceGeometry.boundingBox.origin.x - (padding/2)
        let cameraAspectRatio = CGFloat(CVPixelBufferGetWidth(buffer))/CGFloat(CVPixelBufferGetHeight(buffer))
        let imageHeight = screenImageSize.width/cameraAspectRatio
        let trueImageSize = CGSize(width: screenImageSize.width, height: imageHeight)
        let displayImageCropFrame = CGRect(x: 0,
                                           y: (trueImageSize.height - screenImageSize.height)/2,
                                           width: screenImageSize.width,
                                           height: screenImageSize.height)
        let faceCropFrame = CGRect(x: cropX,
                                   y: cropY,
                                   width: faceCropWidthAndHeight,
                                   height: faceCropWidthAndHeight)


        // scale down the original buffer to match the size of whats displayed on screen
        guard let scaledDownBuffer = resizePixelBuffer(buffer, size: trueImageSize) else { return nil }

        // clip the parts of the buffer that aren't displayed on screen
        guard let clippedBuffer = resizePixelBuffer(scaledDownBuffer,
                                                    cropFrame: displayImageCropFrame,
                                                    scaleSize: screenImageSize) else {
            return nil
        }

        // crop face from the buffer returned in the above operation
        guard let croppedFaceBuffer = resizePixelBuffer(clippedBuffer, cropFrame: faceCropFrame, scaleSize: finalSize) else {
            return nil
        }

        // convert the cropped face buffer to JPG
        return cvImageBufferToJPG(imageBuffer: croppedFaceBuffer, isGreyScale: isGreyScale)
    }

    /**
     Converts a pixel buffer to a JPG image with an isGreyScale
     parameter to apply a grey scale filter to the resulting image.
     */
    private class func cvImageBufferToJPG(imageBuffer: CVImageBuffer, isGreyScale: Bool) -> Data? {
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

    private class func metalCompatiblityAttributes() -> [String: Any] {
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
     Creates a pixel buffer of the specified size, and pixel format.
     - Note: This pixel buffer is backed by an IOSurface and therefore can be
     turned into a Metal texture.
     */
    private class func createPixelBuffer(size: CGSize, pixelFormat: OSType) -> CVPixelBuffer? {
        let attributes = metalCompatiblityAttributes() as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(nil,
                                         Int(size.width),
                                         Int(size.height),
                                         pixelFormat, attributes,
                                         &pixelBuffer)
        if status != kCVReturnSuccess {
            print("Error: could not create pixel buffer", status)
            print("Error: could not create pixel buffer", status)
            return nil
        }
        return pixelBuffer
    }

    private class func resizePixelBuffer(from srcPixelBuffer: CVPixelBuffer,
                                         to dstPixelBuffer: CVPixelBuffer,
                                         cropFrame: CGRect,
                                         scaleSize: CGSize) {
        let scaleWidth = Int(scaleSize.width)
        let scaleHeight = Int(scaleSize.height)
        let cropX = Int(cropFrame.origin.x)
        let cropY = Int(cropFrame.origin.y)
        let cropWidth = Int(cropFrame.size.width)
        let cropHeight = Int(cropFrame.size.height)
        assert(CVPixelBufferGetWidth(dstPixelBuffer) >= scaleWidth)
        assert(CVPixelBufferGetHeight(dstPixelBuffer) >= scaleHeight)

        let srcFlags = CVPixelBufferLockFlags.readOnly
        let dstFlags = CVPixelBufferLockFlags(rawValue: 0)

        guard kCVReturnSuccess == CVPixelBufferLockBaseAddress(srcPixelBuffer, srcFlags) else {
            print("Error: could not lock source pixel buffer")
            return
        }
        defer { CVPixelBufferUnlockBaseAddress(srcPixelBuffer, srcFlags) }

        guard kCVReturnSuccess == CVPixelBufferLockBaseAddress(dstPixelBuffer, dstFlags) else {
            print("Error: could not lock destination pixel buffer")
            return
        }
        defer { CVPixelBufferUnlockBaseAddress(dstPixelBuffer, dstFlags) }

        guard let srcData = CVPixelBufferGetBaseAddress(srcPixelBuffer),
              let dstData = CVPixelBufferGetBaseAddress(dstPixelBuffer) else {
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
        }
    }

    /**
     Resizes a CVPixelBuffer to a new width and height.
     This function requires the caller to pass in both the source and destination
     pixel buffers. The dimensions of destination pixel buffer should be at least
     `width` x `height` pixels.
     */
    private class func resizePixelBuffer(from srcPixelBuffer: CVPixelBuffer,
                                         to dstPixelBuffer: CVPixelBuffer,
                                         scaleSize: CGSize) {
        let cropFrame = CGRect(x: 0,
                               y: 0,
                               width: CVPixelBufferGetWidth(srcPixelBuffer),
                               height: CVPixelBufferGetHeight(srcPixelBuffer))
        resizePixelBuffer(from: srcPixelBuffer,
                          to: dstPixelBuffer,
                          cropFrame: cropFrame,
                          scaleSize: scaleSize)
    }

    /**
     First crops the pixel buffer, then resizes it.
     This allocates a new destination pixel buffer that is Metal-compatible.
     */
    private class func resizePixelBuffer(_ srcPixelBuffer: CVPixelBuffer,
                                         cropFrame: CGRect,
                                         scaleSize: CGSize) -> CVPixelBuffer? {

        let pixelFormat = CVPixelBufferGetPixelFormatType(srcPixelBuffer)
        let dstPixelBuffer = createPixelBuffer(size: scaleSize,
                                               pixelFormat: pixelFormat)

        if let dstPixelBuffer = dstPixelBuffer {
            CVBufferPropagateAttachments(srcPixelBuffer, dstPixelBuffer)

            resizePixelBuffer(from: srcPixelBuffer, to: dstPixelBuffer,
                              cropFrame: cropFrame,
                              scaleSize: scaleSize)
        }

        return dstPixelBuffer
    }

    /**
     Resizes a CVPixelBuffer to a new width and height.
     This allocates a new destination pixel buffer that is Metal-compatible.
     */
    private class func resizePixelBuffer(_ pixelBuffer: CVPixelBuffer,
                                         size: CGSize) -> CVPixelBuffer? {
        let imageWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let imageHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let cropFrame = CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight)
        return resizePixelBuffer(pixelBuffer,
                                 cropFrame: cropFrame,
                                 scaleSize: size)
    }
}
