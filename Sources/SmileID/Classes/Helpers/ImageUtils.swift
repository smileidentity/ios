import CoreVideo
import AVFoundation
import CoreImage
import UIKit
import VideoToolbox
import Accelerate
import Vision
import MobileCoreServices

class ImageUtils {
    class func resizePixelBufferToHeight(
        _ pixelBuffer: CVPixelBuffer,
        height: Int,
        exif: [String: Any]?,
        orientation: CGImagePropertyOrientation = .right
    ) -> Data? {
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

        let newWidth = Int(CGFloat(height) / aspectRatio)

        guard let resizedImage = resizeCGImage(
            cgImage,
            newWidth: newWidth,
            newHeight: height
        )
        else {
            return nil
        }
        return convertCGImageToJPG(cgImage: resizedImage, exifDictionary: exif)
    }

    private class func resizeCGImage(
        _ originalImage: CGImage,
        newWidth: Int,
        newHeight: Int
    ) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil, width: newWidth,
            height: newHeight,
            bitsPerComponent: 8,
            bytesPerRow: newWidth * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        else {
            return nil
        }
        context.interpolationQuality = .high
        context.draw(originalImage, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        return context.makeImage()
    }

    private class func convertCGImageToJPG(
        cgImage: CGImage,
        compressionQuality: CGFloat = 0.8,
        exifDictionary: [String: Any]? = nil
    ) -> Data? {
        let jpgData = NSMutableData()

        guard let destination = CGImageDestinationCreateWithData(jpgData, kUTTypeJPEG, 1, nil)
        else {
            return nil
        }

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
        let status = CVPixelBufferCreate(
            nil,
            Int(size.width),
            Int(size.height),
            pixelFormat,
            attributes,
            &pixelBuffer
        )
        if status != kCVReturnSuccess {
            print("Error: could not create pixel buffer", status)
            return nil
        }
        return pixelBuffer
    }

    class func resizePixelBuffer(
        from srcPixelBuffer: CVPixelBuffer,
        to dstPixelBuffer: CVPixelBuffer,
        cropFrame: CGRect,
        scaleSize: CGSize
    ) {
        let ciImage = CIImage(cvPixelBuffer: srcPixelBuffer)

        // Create a new CIImage with the specified crop and scale
        let croppedImage = ciImage.cropped(to: cropFrame)
        let scaledImage = croppedImage.transformed(
            by: CGAffineTransform(
                scaleX: scaleSize.width / croppedImage.extent.width,
                y: scaleSize.height / croppedImage.extent.height
            )
        )

        // Create a CIContext to render the CIImage to the destination pixel buffer
        let ciContext = CIContext(options: nil)

        // Render the CIImage to the destination pixel buffer
        ciContext.render(scaledImage, to: dstPixelBuffer)
    }

    private class func resizePixelBuffer(
        _ srcPixelBuffer: CVPixelBuffer,
        cropFrame: CGRect,
        scaleSize: CGSize
    ) -> CVPixelBuffer? {

        let pixelFormat = CVPixelBufferGetPixelFormatType(srcPixelBuffer)
        let dstPixelBuffer = createPixelBuffer(
            size: scaleSize,
            pixelFormat: pixelFormat
        )

        if let dstPixelBuffer = dstPixelBuffer {
            CVBufferPropagateAttachments(srcPixelBuffer, dstPixelBuffer)

            resizePixelBuffer(
                from: srcPixelBuffer, to: dstPixelBuffer,
                cropFrame: cropFrame,
                scaleSize: scaleSize
            )
        }

        return dstPixelBuffer
    }
}
