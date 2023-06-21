import CoreVideo
import CoreImage
import UIKit
import VideoToolbox
import Accelerate
import Vision
import MobileCoreServices

class ImageUtils {

    /// Converts a buffer to JPG cropping the  face and returning the result of this operation
    /// - Parameters:
    ///   - buffer: An input pixel buffer
    ///   - faceGeometry: A FaceGeometry object containing the frame of a detected face in the views coordinate system
    ///   - finalSize: Final size of the cropped image
    ///   - screenImageSize: Size of the view the camera feed is displayed
    ///   - isGreyScale: A boolean flag, if true returns a greyscaled image
    /// - Returns: An optional JPG image data returned from the cropping and resizing operation
    class func captureFace(from buffer: CVPixelBuffer,
                           faceGeometry: FaceGeometryModel,
                           padding: CGFloat,
                           finalSize: CGSize,
                           screenImageSize: CGSize,
                           isLivenessImage: Bool) -> Data? {
        guard !faceGeometry.boundingBox.isNaN else { return nil }

        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags.readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags.readOnly)}
        let cameraAspectRatio = CGFloat(CVPixelBufferGetWidth(buffer))/CGFloat(CVPixelBufferGetHeight(buffer))
        let imagewidth = screenImageSize.height * cameraAspectRatio
        let trueImageSize = CGSize(width: imagewidth, height: screenImageSize.height)

        // ratio of the true image width to displayed image width
        let cutoffregion: CGFloat = max(imagewidth, screenImageSize.width) / min(imagewidth, screenImageSize.width)

        // scale down the original buffer to match the size of whats displayed on screen
        guard let scaledDownBuffer = resizePixelBuffer(buffer, size: trueImageSize) else { return nil }

        // calculate crop rect
        let cropRect = CGRect(x: faceGeometry.boundingBox.origin.x * cutoffregion,
                              y: faceGeometry.boundingBox.origin.y,
                              width: faceGeometry.boundingBox.width,
                              height: faceGeometry.boundingBox.height)
        let finalrect = isLivenessImage ?  increaseRect(rect: cropRect, byPercentage: 0.6) : increaseRect(rect: cropRect,
                                                                                                      byPercentage: 1)

        // crop face from the buffer returned in the above operation and return jpg
        return cropFace(scaledDownBuffer,
                        cropFrame: finalrect,
                        scaleSize: finalSize,
                        isLivenessImage: isLivenessImage)
    }

    private class func increaseRect(rect: CGRect, byPercentage percentage: CGFloat) -> CGRect {
        let startWidth = rect.width
        let startHeight = rect.height
        let adjustmentWidth = (startWidth * percentage) / 2.0
        let adjustmentHeight = (startHeight * percentage) / 2.0
        return rect.insetBy(dx: -adjustmentWidth, dy: -adjustmentHeight)
    }

    private class func cropFace(_ buffer: CVPixelBuffer,
                                cropFrame: CGRect,
                                scaleSize: CGSize,
                                isLivenessImage: Bool = true) -> Data? {
        var ciImage = CIImage(cvPixelBuffer: buffer)
        guard let cgImage = convertCIImageToCGImage(ciImage: ciImage) else { return nil }
        guard let croppedImage = cgImage.cropping(to: cropFrame)?.resize(size: scaleSize) else { return nil }
        return convertCGImageToJPG(cgImage: croppedImage)
    }

    private class func convertCGImageToJPG(cgImage: CGImage, compressionQuality: CGFloat = 0.8) -> Data? {
        let jpgData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(jpgData, kUTTypeJPEG, 1, nil) else { return nil }

        let options: [String: Any] = [
            kCGImageDestinationLossyCompressionQuality as String: compressionQuality
        ]

        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)

        guard CGImageDestinationFinalize(destination) else { return nil }

        return jpgData as Data
    }

    private class func convertCIImageToCGImage(ciImage: CIImage) -> CGImage? {
        let context = CIContext(options: nil)
        return context.createCGImage(ciImage, from: ciImage.extent)
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

    class func resizePixelBuffer(from srcPixelBuffer: CVPixelBuffer,
                                 to dstPixelBuffer: CVPixelBuffer,
                                 cropFrame: CGRect,
                                 scaleSize: CGSize) {
        let ciImage = CIImage(cvPixelBuffer: srcPixelBuffer)

        // Create a new CIImage with the specified crop and scale
        let croppedImage = ciImage.cropped(to: cropFrame)
        let scaledImage = croppedImage.transformed(by: CGAffineTransform(
            scaleX: scaleSize.width / croppedImage.extent.width,
            y: scaleSize.height / croppedImage.extent.height))

        // Create a CIContext to render the CIImage to the destination pixel buffer
        let ciContext = CIContext(options: nil)

        // Render the CIImage to the destination pixel buffer
        ciContext.render(scaledImage, to: dstPixelBuffer)
    }

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

extension CGImage {
    func resize(size: CGSize) -> CGImage? {
        let width: Int = Int(size.width)
        let height: Int = Int(size.height)

        let bytesPerPixel = self.bitsPerPixel / self.bitsPerComponent
        let destBytesPerRow = width * bytesPerPixel

        guard let colorSpace = self.colorSpace else { return nil }
        guard let context = CGContext(data: nil,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: self.bitsPerComponent,
                                      bytesPerRow: destBytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: self.alphaInfo.rawValue) else { return nil }

        context.interpolationQuality = .high
        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))

        return context.makeImage()
    }
}
