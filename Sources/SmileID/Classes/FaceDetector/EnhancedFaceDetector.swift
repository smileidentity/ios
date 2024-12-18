import AVFoundation
import Combine
import UIKit
import Vision

enum FaceDetectorError: Error {
    case unableToLoadSelfieModel
    case invalidSelfieModelOutput
    case noFaceDetected
    case multipleFacesDetected
    case unableToCropImage
}

protocol FaceDetectorViewDelegate: NSObjectProtocol {
    func convertFromMetadataToPreviewRect(rect: CGRect) -> CGRect
}

protocol FaceDetectorResultDelegate: AnyObject {
    func faceDetector(
        _ detector: EnhancedFaceDetector,
        didDetectFace faceGeometry: FaceGeometryData,
        withFaceQuality faceQuality: Float,
        brightness: Int
    )
    func faceDetector(_ detector: EnhancedFaceDetector, didFailWithError error: Error)
}

class EnhancedFaceDetector: NSObject {
    private var selfieQualityModel: SelfieQualityDetector?

    private let cropSize = (width: 120, height: 120)
    private let faceMovementThreshold: CGFloat = 0.15

    private var sequenceHandler = VNSequenceRequestHandler()

    weak var viewDelegate: FaceDetectorViewDelegate?
    weak var resultDelegate: FaceDetectorResultDelegate?

    override init() {
        super.init()
        selfieQualityModel = createImageClassifier()
    }

    private func createImageClassifier() -> SelfieQualityDetector? {
        do {
            let modelConfiguration = MLModelConfiguration()
            let coreMLModel = try SelfieQualityDetector(configuration: modelConfiguration)
            return coreMLModel
        } catch {
            return nil
        }
    }

    /// Run Face Capture quality and Face Bounding Box and roll/pitch/yaw tracking
    func processImageBuffer(_ imageBuffer: CVPixelBuffer) {
        let detectFaceRectanglesRequest = VNDetectFaceRectanglesRequest()
        let detectCaptureQualityRequest = VNDetectFaceCaptureQualityRequest()

        do {
            try sequenceHandler.perform(
                [detectFaceRectanglesRequest, detectCaptureQualityRequest],
                on: imageBuffer,
                orientation: .leftMirrored
            )
            guard let faceDetections = detectFaceRectanglesRequest.results,
                let faceQualityObservations = detectCaptureQualityRequest.results,
                let faceObservation = faceDetections.first,
                let faceQualityObservation = faceQualityObservations.first
            else {
                self.resultDelegate?.faceDetector(
                    self, didFailWithError: FaceDetectorError.noFaceDetected)
                return
            }

            guard faceDetections.count == 1 else {
                self.resultDelegate?.faceDetector(self, didFailWithError: FaceDetectorError.multipleFacesDetected)
                return
            }

            let convertedBoundingBox =
                self.viewDelegate?.convertFromMetadataToPreviewRect(
                    rect: faceObservation.boundingBox) ?? .zero

            let uiImage = UIImage(pixelBuffer: imageBuffer)
            let brightness = self.calculateBrightness(uiImage)

            let faceGeometryData: FaceGeometryData
            if #available(iOS 15.0, *) {
                faceGeometryData = FaceGeometryData(
                    boundingBox: convertedBoundingBox,
                    roll: faceObservation.roll ?? 0.0,
                    yaw: faceObservation.yaw ?? 0.0,
                    pitch: faceObservation.pitch ?? 0.0,
                    direction: faceDirection(faceObservation: faceObservation)
                )
            } else { // Fallback on earlier versions
                faceGeometryData = FaceGeometryData(
                    boundingBox: convertedBoundingBox,
                    roll: faceObservation.roll ?? 0.0,
                    yaw: faceObservation.yaw ?? 0.0,
                    pitch: 0.0,
                    direction: faceDirection(faceObservation: faceObservation)
                )
            }
            self.resultDelegate?
                .faceDetector(
                    self,
                    didDetectFace: faceGeometryData,
                    withFaceQuality: faceQualityObservation.faceCaptureQuality ?? 0.0,
                    brightness: brightness
                )
        } catch {
            self.resultDelegate?.faceDetector(self, didFailWithError: error)
        }
    }

    func selfieQualityRequest(imageBuffer: CVPixelBuffer) throws -> SelfieQualityData {
        guard let selfieQualityModel else {
            throw FaceDetectorError.unableToLoadSelfieModel
        }
        let input = SelfieQualityDetectorInput(conv2d_193_input: imageBuffer)

        let prediction = try selfieQualityModel.prediction(input: input)
        let output = prediction.Identity

        guard output.shape.count == 2,
            output.shape[0] == 1,
            output.shape[1] == 2
        else {
            throw FaceDetectorError.invalidSelfieModelOutput
        }

        let passScore = output[0].floatValue
        let failScore = output[1].floatValue

        let selfieQualityData = SelfieQualityData(
            failed: failScore,
            passed: passScore
        )
        return selfieQualityData
    }

    private func cropImageToFace(
        _ image: UIImage?
    ) throws -> CVPixelBuffer {
        guard let image, let cgImage = image.cgImage else {
            throw FaceDetectorError.unableToCropImage
        }

        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        try handler.perform([request])

        guard let results = request.results,
            let face = results.first
        else {
            throw FaceDetectorError.noFaceDetected
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

        guard let croppedCGImage = cgImage.cropping(to: faceRect) else {
            throw FaceDetectorError.unableToCropImage
        }

        let croppedImage = UIImage(cgImage: croppedCGImage)
        guard
            let resizedImage = croppedImage.pixelBuffer(
                width: cropSize.width, height: cropSize.height)
        else {
            throw FaceDetectorError.unableToCropImage
        }

        return resizedImage
    }

    private func calculateBrightness(_ image: UIImage?) -> Int {
        guard let image, let cgImage = image.cgImage,
              let imageData = cgImage.dataProvider?.data,
              let dataPointer = CFDataGetBytePtr(imageData)
        else {
            return 0
        }

        let bytesPerPixel = cgImage.bitsPerPixel / cgImage.bitsPerComponent
        let dataLength = CFDataGetLength(imageData)
        var result = 0.0
        for index in stride(from: 0, to: dataLength, by: bytesPerPixel) {
            let red = dataPointer[index]
            let green = dataPointer[index + 1]
            let blue = dataPointer[index + 2]
            result += 0.299 * Double(red) + 0.587 * Double(green) + 0.114 * Double(blue)
        }
        let pixelsCount = dataLength / bytesPerPixel
        let brightness = Int(result) / pixelsCount
        return brightness
    }

    private func faceDirection(faceObservation: VNFaceObservation) -> FaceDirection {
        guard let yaw = faceObservation.yaw?.doubleValue else {
            return .none
        }
        let yawInRadians = CGFloat(yaw)

        if yawInRadians > faceMovementThreshold {
            return .right
        } else if yawInRadians < -faceMovementThreshold {
            return .left
        } else {
            return .none
        }
    }
}
