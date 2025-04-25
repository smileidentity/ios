import Foundation
import UIKit

class ImgUtils {
    /**
     * UIImage pixels to ARGB array.
     * Converts pixel data to an ARGB int array.
     */
    static func pixel2ARGBArray(inputPixels: [UInt32]) -> [Int] {
        var bitmapArray = [Int](repeating: 0, count: 4 * inputPixels.count)

        for index in 0 ..< inputPixels.count {
            let pixel = inputPixels[index]
            // Extract ARGB components
            let alpha = Int((pixel >> 24) & 0xFF)
            let red = Int((pixel >> 16) & 0xFF)
            let green = Int((pixel >> 8) & 0xFF)
            let blue = Int(pixel & 0xFF)

            bitmapArray[4 * index] = alpha
            bitmapArray[4 * index + 1] = red
            bitmapArray[4 * index + 2] = green
            bitmapArray[4 * index + 3] = blue
        }

        return bitmapArray
    }

    /**
     * Get pixel data from a UIImage
     */
    static func getPixelData(from image: UIImage) -> [UInt32]? {
        guard let cgImage = image.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var pixelData = [UInt32](repeating: 0, count: width * height)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue |
            CGBitmapInfo.byteOrder32Big.rawValue
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        return pixelData
    }

    /**
     * Create a UIImage from pixel data
     */
    static func createImage(pixelData: [UInt32], width: Int, height: Int) -> UIImage? {
        guard width > 0, height > 0, pixelData.count == width * height else { return nil }

        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var data = pixelData

        guard let context = CGContext(
            data: &data,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else {
            return nil
        }

        guard let cgImage = context.makeImage() else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
