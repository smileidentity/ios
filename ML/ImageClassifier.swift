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
    func classify(imageBuffer: CVPixelBuffer) async throws -> ImageQualityResult {
        do {
            guard let image = UIImage(pixelBuffer: imageBuffer) else {
                throw ImageClassifierError.preprocessingFailed
            }
            let croppedImage = try await cropToFace(image: image)
            guard let convertedImage = croppedImage.pixelBuffer(width: 120, height: 120) else {
                throw ImageClassifierError.preprocessingFailed
            }
            return try performClassification(imageBuffer: convertedImage)
        } catch {
            throw error
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

    /// Performs the actual classification using the `ImageQualityCP20` model
    /// - Parameter mlMultiArray: The processed input image as a MultiArray
    /// - Returns: The ImageQualityResult
    private func performClassification(imageBuffer: CVPixelBuffer) throws -> ImageQualityResult {
        let modelConfiguration = MLModelConfiguration()
        let model = try SelfieQualityDetector(configuration: modelConfiguration)

        let input = SelfieQualityDetectorInput(conv2d_193_input: imageBuffer)

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
