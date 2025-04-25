import Foundation
import os.log
import UIKit

// Tobi thou shalt not say anything speaking of which
// https://developer.apple.com/documentation/os/oslog is actually good,
// should we have a logging helper to remove the scattered print() all over?

let errorPixelsNotEnough = "Not enough pixels"
let lsbPrefixFlag = "2323"
let lsbSuffixFlag = "4545"

class WaterMarkUtils {
    /**
     * Creates an invisible text watermark in an image from Data and saves it to a file
     */
    static func createInvisibleTextMark(imageData: Data, file: URL) {
        do {
            guard let backgroundImg = UIImage(data: imageData) else {
                os_log("Failed to create UIImage from data", log: .default, type: .error)
                return
            }

            let runId = UUID().uuidString
            let useNativeProcessor = false
            let applyProcessors = true
            let session = BenchMarkUtils.createSession(
                operationName: "createInvisibleTextMark  run id = \(runId)"
            )

            session.lap(lapName: "Watermark Start")
            session.recordFileSize(name: "liveness", filePath: file.path)

            if applyProcessors {
                let regionWidth = Int(Double(backgroundImg.size.width) * 0.2)
                let regionHeight = Int(Double(backgroundImg.size.height) * 0.1)
                let startX = Int(backgroundImg.size.width) - regionWidth
                let startY = Int(backgroundImg.size.height) - regionHeight

                let watermarkText = WatermarkText(
                    text: "Smile Identity",
                    position: WatermarkPosition(
                        positionX: startX,
                        positionY: startY,
                        width: regionWidth,
                        height: regionHeight
                    )
                )

                let result = try applyWatermark(
                    backgroundImg: backgroundImg,
                    watermarkText: watermarkText,
                    useNativeProcessor: useNativeProcessor
                )

                session.lap(lapName: "Watermark applied")

                // Save the watermarked image to file
                if let resultData = result.jpegData(compressionQuality: 1.0) {
                    try resultData.write(to: file)
                    session.lap(lapName: "File created")
                    os_log("Done creating invisible watermark", log: .default, type: .info)
                }

                session.lap(lapName: "Watermark application complete")

                // Now detect the watermark we just created
                session.lap(lapName: "Watermark detection start")
                let detectionResult = try detectWatermark(uiImage: result, useNativeProcessor: useNativeProcessor)

                // Get the detected watermark text
                let detectedText = detectionResult.watermarkString
                session.lap(lapName: "Watermark detection complete result \(detectedText ?? "nil")")
            }

            session.lap(lapName: "Watermark indy complete result")
            session.stop(finalMessage: "createInvisibleTextMark  run id = \(runId)")
        } catch {
            os_log("Error creating invisible watermark: %@", log: .default, type: .error, error.localizedDescription)
        }
    }

    /**
     * Applies a watermark to an image
     */
    static func applyWatermark(
        backgroundImg: UIImage,
        watermarkText: WatermarkText,
        useNativeProcessor: Bool = true
    ) throws -> UIImage {
        do {
            // Define the region to watermark
            let regionWidth = watermarkText.position.width
            let regionHeight = watermarkText.position.height
            let startX = watermarkText.position.positionX
            let startY = watermarkText.position.positionY

            // Create a new image context with the same size as the original image
            UIGraphicsBeginImageContextWithOptions(backgroundImg.size, false, backgroundImg.scale)
            defer { UIGraphicsEndImageContext() }

            // Draw the original image
            backgroundImg.draw(at: .zero)

            // Get the region pixels
            guard let regionPixels = getRegionPixels(
                from: backgroundImg,
                xPos: startX,
                yPos: startY,
                width: regionWidth,
                height: regionHeight
            ) else {
                throw NSError(domain: "WatermarkError", code: 1,
                              userInfo: [NSLocalizedDescriptionKey: "Failed to get region pixels"])
            }

            // Convert the region pixels to ARGB array
            let regionColorArray = ImgUtils.pixel2ARGBArray(inputPixels: regionPixels)

            // Convert the String into a binary string
            var watermarkBinary = if useNativeProcessor {
                StringUtils.stringToBinary(watermarkText.text)
            } else {
                StringUtils.nonNativeStringToBinary(watermarkText.text)
            }

            watermarkBinary = lsbPrefixFlag + (watermarkBinary ?? "") + lsbSuffixFlag

            let watermarkColorArray = if useNativeProcessor {
                StringUtils.stringToIntArray(watermarkBinary)
            } else {
                StringUtils.nonNativeStringToIntArray(watermarkBinary)
            }

            guard let watermarkArray = watermarkColorArray else {
                throw NSError(domain: "WatermarkError", code: 2,
                              userInfo: [NSLocalizedDescriptionKey:
                                  "Failed to create watermark array"])
            }

            if watermarkArray.count > regionColorArray.count {
                os_log("Watermark return 1 - region too small for watermark", log: .default, type: .info)
                throw NSError(domain: "WatermarkError", code: 3,
                              userInfo: [NSLocalizedDescriptionKey: errorPixelsNotEnough])
            }

            // Apply the watermark by replacing LSBs only in the region
            let chunkSize = watermarkArray.count
            let numOfChunks = Int(ceil(Double(regionColorArray.count) / Double(chunkSize)))

            var modifiedRegionColorArray = regionColorArray

            for index in 0 ..< min(numOfChunks, 1) { // Apply only once in the region
                let start = index * chunkSize
                for jIndex in 0 ..< chunkSize {
                    if start + jIndex < modifiedRegionColorArray.count {
                        modifiedRegionColorArray[start + jIndex] = StringUtils.replaceSingleDigit(
                            target: modifiedRegionColorArray[start + jIndex],
                            singleDigit: watermarkArray[jIndex]
                        )
                    }
                }
            }

            // Reconstruct the modified region pixel array
            var modifiedRegionPixels = [UInt32](repeating: 0, count: regionPixels.count)

            for index in 0 ..< regionPixels.count {
                let alpha = UInt32(modifiedRegionColorArray[4 * index]) << 24
                let red = UInt32(modifiedRegionColorArray[4 * index + 1]) << 16
                let green = UInt32(modifiedRegionColorArray[4 * index + 2]) << 8
                let blue = UInt32(modifiedRegionColorArray[4 * index + 3])

                modifiedRegionPixels[index] = UInt32(alpha | red | green | blue)
            }

            // Draw the modified region on top of the original image
            if let modifiedRegionImage = ImgUtils.createImage(
                pixelData: modifiedRegionPixels,
                width: regionWidth,
                height: regionHeight
            ) {
                modifiedRegionImage.draw(at: CGPoint(x: startX, y: startY))
            }

            // Get the resulting image
            guard let outputImage = UIGraphicsGetImageFromCurrentImageContext() else {
                throw NSError(domain: "WatermarkError", code: 4,
                              userInfo: [NSLocalizedDescriptionKey: "Failed to create output image"])
            }

            return outputImage
        } catch {
            os_log("Error applying LSB watermark: %@", log: .default, type: .error, error.localizedDescription)
            throw error
        }
    }

    /**
     * Detects a watermark in an image
     */
    static func detectWatermark(uiImage: UIImage, useNativeProcessor: Bool = true) throws -> DetectionResults {
        do {
            // Define the same region used for watermarking
            let regionWidth = Int(Double(uiImage.size.width) * 0.2)
            let regionHeight = Int(Double(uiImage.size.height) * 0.1)
            let startX = Int(uiImage.size.width) - regionWidth
            let startY = Int(uiImage.size.height) - regionHeight

            // Get the region pixels
            guard let regionPixels = getRegionPixels(
                from: uiImage,
                xPos: startX,
                yPos: startY,
                width: regionWidth,
                height: regionHeight
            ) else {
                throw NSError(domain: "WatermarkError", code: 5,
                              userInfo: [NSLocalizedDescriptionKey:
                                  "Failed to get region pixels for detection"])
            }

            // Extract the LSB values from the region
            let regionColorArray = ImgUtils.pixel2ARGBArray(inputPixels: regionPixels)
            var extractedBinary = ""

            for index in 0 ..< regionColorArray.count {
                extractedBinary += String(regionColorArray[index] % 10)
            }

            // Look for the text prefix and suffix markers
            guard let textStartIndex = extractedBinary.range(of: lsbPrefixFlag)?.lowerBound else {
                return DetectionResults(watermarkString: nil)
            }

            let searchStartIndex = extractedBinary.index(textStartIndex, offsetBy: lsbPrefixFlag.count)
            guard let textEndIndex = extractedBinary.range(of: lsbSuffixFlag,
                                                           range: searchStartIndex ..< extractedBinary.endIndex)?.lowerBound else {
                return DetectionResults(watermarkString: nil)
            }

            // Extract the text portion
            let textBinary = String(extractedBinary[searchStartIndex ..< textEndIndex])

            // Convert binary back to text
            let extractedText = if useNativeProcessor {
                StringUtils.binaryToString(textBinary)
            } else {
                StringUtils.nonNativeBinaryToString(textBinary)
            }

            return DetectionResults(watermarkString: extractedText)
        } catch {
            os_log("Error detecting watermark: %@", log: .default, type: .error, error.localizedDescription)
            throw error
        }
    }

    /**
     * Helper function to get pixels from a specific region of a UIImage
     */
    private static func getRegionPixels(from image: UIImage, xPos: Int,
                                        yPos: Int, width: Int, height: Int) -> [UInt32]?
    {
        guard let cgImage = image.cgImage else { return nil }

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
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else {
            return nil
        }

        // Calculate the crop rectangle in the original image's coordinate space
        guard let croppedCGImage = cgImage.cropping(to: CGRect(x: xPos, y: yPos, width: width, height: height)) else {
            return nil
        }

        context.draw(croppedCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        return pixelData
    }

    /**
     * Generate a random job ID (UUID)
     */
    static func randomJobId() -> String {
        return UUID().uuidString
    }
}

extension WaterMarkUtils {
    /**
     * Detects a watermark in image data
     *
     * @param imageData The image data to detect watermark in
     * @param useNativeProcessor Whether to use native processing methods
     * @return Detection results containing the watermark string if found
     */
    static func detectWatermark(imageData: Data, useNativeProcessor:
        Bool = true) throws -> DetectionResults
    {
        guard let image = UIImage(data: imageData) else {
            throw NSError(domain: "WatermarkError", code: 6, userInfo:
                [NSLocalizedDescriptionKey: "Failed to create image from data"])
        }

        return try detectWatermark(uiImage: image, useNativeProcessor: useNativeProcessor)
    }

    /**
     * Async version of detectWatermark that works with image data
     *
     * @param imageData The image data to detect watermark in
     * @param useNativeProcessor Whether to use native processing methods
     * @return Detection results containing the watermark string if found
     */
    @available(iOS 13.0, *)
    static func detectWatermarkAsync(imageData: Data,
                                     useNativeProcessor: Bool = true)
        async throws -> DetectionResults
    {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let result = try detectWatermark(imageData: imageData,
                                                     useNativeProcessor: useNativeProcessor)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /**
     *
     * Quick checks where error handling isn't critical
     * @param imageData The image data to detect watermark in
     * @return The detected watermark string or nil if not found or error occurred
     */
    static func extractWatermarkString(from imageData: Data) -> String? {
        do {
            let results = try detectWatermark(imageData: imageData)
            return results.watermarkString
        } catch {
            os_log("Failed to extract watermark: %@",
                   log: .default, type: .error, error.localizedDescription)
            return nil
        }
    }

    /**
     * Async version of extractWatermarkString
     *
     * @param imageData The image data to detect watermark in
     * @return The detected watermark string or nil if not found or error occurred
     */
    @available(iOS 13.0, *)
    static func extractWatermarkStringAsync(from imageData: Data) async -> String? {
        do {
            let results = try await detectWatermarkAsync(imageData: imageData)
            return results.watermarkString
        } catch {
            os_log("Failed to extract watermark: %@", log: .default, type: .error, error.localizedDescription)
            return nil
        }
    }
}
