import CoreVideo
import AVFoundation
import CoreImage
import UIKit
import VideoToolbox
import Accelerate
import Vision
import AVFoundation
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
                           agentMode: Bool,
                           finalSize: CGSize,
                           screenImageSize: CGSize,
                           isSelfie: Bool,
                           orientation: CGImagePropertyOrientation = .right
    ) -> Data? {
        guard !faceGeometry.boundingBox.isNaN else { return nil }
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags.readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags.readOnly)}
        let cameraAspectRatio = CGFloat(CVPixelBufferGetWidth(buffer))/CGFloat(CVPixelBufferGetHeight(buffer))
        let imagewidth = screenImageSize.height * cameraAspectRatio
        let imageHeight = screenImageSize.width * cameraAspectRatio
        let trueImageSize = CGSize(width: imagewidth, height: screenImageSize.height)

        // ratio of the true image width to displayed image width
        let ycuttoffregionAgentMode: CGFloat = max(imageHeight, screenImageSize.width) / min(imageHeight, screenImageSize.width)
        let xcutoffregion: CGFloat = max(imagewidth, screenImageSize.width) / min(imagewidth, screenImageSize.width)
        let ycutoffregion: CGFloat = max(imageHeight, screenImageSize.height) / min(imageHeight, screenImageSize.height)
        // scale down the original buffer to match the size of whats displayed on screen
        guard let scaledDownBuffer = resizePixelBuffer(buffer, size: trueImageSize) else { return nil }

        // calculate crop rect

        let cropL = max(faceGeometry.boundingBox.width, faceGeometry.boundingBox.height)
        let cropRect = agentMode ? CGRect(x: faceGeometry.boundingBox.origin.y * ycuttoffregionAgentMode,
                                          y: faceGeometry.boundingBox.origin.y * ycuttoffregionAgentMode,
                                          width: cropL,
                                          height: cropL) : CGRect(x: faceGeometry.boundingBox.origin.x * xcutoffregion,
                                                                  y: faceGeometry.boundingBox.origin.y * ycutoffregion,
                                                                  width: cropL,
                                                                  height: cropL)
        let finalrect = agentMode ? increaseRect(rect: cropRect,
                                                 byPercentage: 1.5) : increaseRect(rect: cropRect, byPercentage: 1)

        // crop face from the buffer returned in the above operation and return jpg
        if isSelfie {
            return cropFace(scaledDownBuffer,
                            cropFrame: finalrect,
                            scaleSize: finalSize, orientation: orientation)
        } else {
            return cropFace(scaledDownBuffer,
                            cropFrame: finalrect,
                            scaleSize: finalSize, orientation: orientation)
        }
    }

    class func resizePixelBufferToWidth(_ pixelBuffer: CVPixelBuffer,
                                        width: Int,
                                        exif: [String: Any]?,
                                        orientation: CGImagePropertyOrientation = .right) -> Data? {
        var image = CIImage(cvPixelBuffer: pixelBuffer)
        image = image.oriented(orientation)
        guard let cgImage = CIContext(options: nil).createCGImage(image, from: image.extent) else {
            return nil
        }

        let originalWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let originalHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))

        var aspectRatio = originalHeight / originalWidth

        // Adjust the aspect ratio for .left/.right orientations
        if orientation == .left || orientation == .right {
            aspectRatio = 1 / aspectRatio
        }

        let newHeight = Int(CGFloat(width) * aspectRatio)

        guard let resizedImage = resizeCGImage(cgImage, newWidth: width, newHeight: newHeight) else {
            return nil
        }
        return convertCGImageToJPG(cgImage: resizedImage, exifDictionary: exif)
    }

    func rotatePixelBuffer(_ pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation) -> CVPixelBuffer? {
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        switch orientation {
        case .left:
            ciImage = ciImage.oriented(.left)
        default:
            return nil
        }

        // Create new pixel buffer
        var newPixelBuffer: CVPixelBuffer? = nil
        CVPixelBufferCreate(kCFAllocatorDefault, Int(ciImage.extent.size.width), Int(ciImage.extent.size.height), CVPixelBufferGetPixelFormatType(pixelBuffer), nil, &newPixelBuffer)

        // Create CIContext
        let context = CIContext()

        // Render the CIImage to the new CVPixelBuffer
        if let newPixelBuffer = newPixelBuffer {
            context.render(ciImage, to: newPixelBuffer)
        }

        return newPixelBuffer
    }

    private class func resizeCGImage(_ originalImage: CGImage, newWidth: Int, newHeight: Int) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: nil, width: newWidth, height: newHeight, bitsPerComponent: 8, bytesPerRow: newWidth * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }
        context.interpolationQuality = .high
        context.draw(originalImage, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        return context.makeImage()
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
                                orientation: CGImagePropertyOrientation,
                                isGreyScale: Bool = false) -> Data? {
        var ciImage = CIImage(cvPixelBuffer: buffer).oriented(orientation)
        if isGreyScale {
            let greyFilter = CIFilter(name: "CIPhotoEffectNoir")
            greyFilter?.setValue(ciImage, forKey: kCIInputImageKey)
            ciImage = greyFilter?.outputImage ?? ciImage
        }
        guard let cgImage = convertCIImageToCGImage(ciImage: ciImage) else { return nil }
        guard let croppedImage = cgImage.cropping(to: cropFrame)?.resize(size: scaleSize) else { return nil }
        return convertCGImageToJPG(cgImage: croppedImage)
    }

    private class func convertCGImageToJPG(cgImage: CGImage, compressionQuality: CGFloat = 0.8, exifDictionary: [String: Any]? = nil) -> Data? {
        let jpgData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(jpgData, kUTTypeJPEG, 1, nil) else { return nil }

        var options: [String: Any] = [
            kCGImageDestinationLossyCompressionQuality as String: compressionQuality
        ]

        if let exifDictionary = exifDictionary {
            let exif = NSMutableDictionary(dictionary: exifDictionary)
            let metadata = NSMutableDictionary()
            metadata.setValue(exif, forKey: kCGImagePropertyExifDictionary as String)
            options[kCGImagePropertyExifDictionary as String] = metadata
        }

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
