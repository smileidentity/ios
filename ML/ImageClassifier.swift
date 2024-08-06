import CoreML
import Vision

enum ImageClassifierError: Error {
    case preprocessingFailed
    case classificationFailed
    case invalidOutputFormat
    case imageConversionFailed
    case faceCroppingFailed
}

struct ImageQualityResult {
    let passed: Bool
    let confidence: Float
    
    var description: String {
        return passed ? "Passed" : "Failed"
    }
}

class ModelImageClassifier {

    init() {}

    func classify(image: UIImage) async throws -> ImageQualityResult {
        do {
            let mlMultiArray = try await preprocessImage(image)
            let output = try performClassification(mlMultiArray: mlMultiArray)
            return output
        } catch {
            throw error
        }
    }
    
    private func preprocessImage(_ image: UIImage) async throws -> MLMultiArray {
        do {
            let croppedImage = try await cropToFace(image: image)
            let multiArray = try imageToMLMultiArray(croppedImage)
            return multiArray
        } catch {
            throw ImageClassifierError.preprocessingFailed
        }
    }

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
        
        let faceRect = VNImageRectForNormalizedRect(face.boundingBox, cgImage.width, cgImage.height)
        
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
            bytesPerRow: width * channels,
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
    
    private func performClassification(mlMultiArray: MLMultiArray) throws -> ImageQualityResult {
        let modelConfiguration = MLModelConfiguration()
        let model = try ImageQualityCP20(configuration: modelConfiguration)
        
        let input = ImageQualityCP20Input(conv2d_193_input: mlMultiArray)
        
        let prediction = try model.prediction(input: input)
        
        guard let output = prediction.featureValue(for: "Identity")?.multiArrayValue else {
            throw ImageClassifierError.classificationFailed
        }
        
        return try processModelOuput(output)
    }

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
