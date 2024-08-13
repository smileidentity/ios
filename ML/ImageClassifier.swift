import CoreML
import Vision

/// An enum representing possible errors during image classification
enum ImageClassifierError: Error {
    case preprocessingFailed
    case classificationFailed
    case invalidOutputFormat
    case imageConversionFailed
    case faceCroppingFailed
}

/// A structure representing the image quality check result
struct ImageQualityResult {
    let passed: Bool
    let confidence: Float

    var description: String {
        return passed ? "Passed" : "Failed"
    }
}

/// A class that performs image classification to determine selfie quality using a Core ML Model
class ModelImageClassifier {

    init() {}

    /// Classifies an image using the Core ML Model
    /// - Parameter image: The input image as a UIImage
    /// - Returns: A result containing classifiction confidence.
    func classify(image: UIImage) async throws -> ImageQualityResult {
        do {
            let mlMultiArray = try await preprocessImage(image)
            let output = try performClassification(mlMultiArray: mlMultiArray)
            return output
        } catch {
            throw error
        }
    }

    /// Preprocesses the input image to match the model's required input format and size.
    /// - Parameter image: The originial input image
    /// - Returns: A MultiArray matching the model's input specifications.
    private func preprocessImage(_ image: UIImage) async throws -> MLMultiArray {
        do {
            let croppedImage = try await cropToFace(image: image)
            let multiArray = try imageToMLMultiArray(croppedImage)
            return multiArray
        } catch {
            throw ImageClassifierError.preprocessingFailed
        }
    }

    /// Crops the input image to the region of the first face in the image.
    /// - Parameter image: The original input image that should have a face.
    /// - Returns: A cropped image of the detected face in the input image.
    private func cropToFace(image: UIImage) async throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw ImageClassifierError.faceCroppingFailed
        }

        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        try handler.perform([request])

        guard let results = request.results,
              let face = results.first else {
            throw ImageClassifierError.faceCroppingFailed
        }

        let boundingBox = face.boundingBox
        
        let size = CGSize(
            width: boundingBox.width * image.size.width,
            height: boundingBox.height * image.size.height
        )
        let origin = CGPoint(
            x: boundingBox.minX * image.size.width,
            y: (1 - boundingBox.minY) * image.size.height - size.height
        )
        
        let faceRect = CGRect(origin: origin, size: size)

        guard let croppedImage = cgImage.cropping(to: faceRect) else {
            throw ImageClassifierError.faceCroppingFailed
        }

        return UIImage(cgImage: croppedImage)
    }

    private func imageToMLMultiArray(_ image: UIImage) throws -> MLMultiArray {
        let inputSize = CGSize(width: 120, height: 120)
        UIGraphicsBeginImageContextWithOptions(inputSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: inputSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let resizedImage = resizedImage,
              let mlMultiArray = toMLMultiArrayInternal(image: resizedImage) else {
            throw ImageClassifierError.preprocessingFailed
        }
        return mlMultiArray
    }

    private func toMLMultiArrayInternal(image: UIImage) -> MLMultiArray? {
        guard let cgImage = image.cgImage else {
            return nil
        }

        // These values were gotten from the model input specification:
        // MultiArray (Float32 1 × 120 × 120 × 3)
        let width = 120
        let height = 120
        let channels = 3

        let array = try? MLMultiArray(
            shape: [
                1, NSNumber(value: height),
                NSNumber(value: width),
                NSNumber(value: channels)],
            dataType: .float32
        )

        guard let mlMultiArray = array else {
            return nil
        }

        let context = CIContext()
        let inputImage = CIImage(cgImage: cgImage)

        guard let bitmap = context.createCGImage(inputImage, from: inputImage.extent) else {
            return nil
        }

        let pixelBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: height * width * channels)
        defer { pixelBuffer.deallocate() }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let contextRef = CGContext(
            data: pixelBuffer,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )

        contextRef?.draw(bitmap, in: CGRect(x: 0, y: 0, width: width, height: height))

        let pointer = UnsafeMutablePointer<Float32>(OpaquePointer(mlMultiArray.dataPointer))

        for yAxis in 0..<height {
            for xAxis in 0..<width {
                let pixelIndex = (yAxis * width * channels) + (xAxis * channels)

                let red = Float32(pixelBuffer[pixelIndex]) / 255.0
                let green = Float32(pixelBuffer[pixelIndex + 1]) / 255.0
                let blue = Float32(pixelBuffer[pixelIndex + 2]) / 255.0

                pointer[pixelIndex + 0] = red
                pointer[pixelIndex + 1] = green
                pointer[pixelIndex + 2] = blue
            }
        }

        return mlMultiArray
    }

    /// Performs the actual classification using the `ImageQualityCP20` model
    /// - Parameter mlMultiArray: The processed input image as a MultiArray
    /// - Returns: The ImageQualityResult
    private func performClassification(mlMultiArray: MLMultiArray) throws -> ImageQualityResult {
        let modelConfiguration = MLModelConfiguration()
        let model = try ImageQualityCP20(configuration: modelConfiguration)

        let input = ImageQualityCP20Input(conv2d_193_input: mlMultiArray)

        let prediction = try model.prediction(input: input)
        let output = prediction.Identity
        return try processModelOuput(output)
    }

    /// Processes the model's output to determine the final classification
    /// - Parameter output: The MLMultiArray output from the model
    /// - Returns: The ImageQualityResult
    private func processModelOuput(_ output: MLMultiArray) throws -> ImageQualityResult {
        guard output.shape.count == 2,
              output.shape[0] == 1,
              output.shape[1] == 2 else {
            throw ImageClassifierError.invalidOutputFormat
        }

        let failScore = output[0].floatValue
        let passScore = output[1].floatValue

        let passed = passScore > failScore
        let confidence = passed ? passScore : failScore

        return ImageQualityResult(passed: passed, confidence: confidence)
    }
}

