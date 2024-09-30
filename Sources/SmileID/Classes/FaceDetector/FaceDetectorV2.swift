import AVFoundation
import Combine
import UIKit
import Vision

enum FaceDetectorError: Error {
    case unableToLoadSelfieModel
    case invalidSelfieModelOutput
    case noFaceDetected
}

protocol FaceDetectorViewDelegate: NSObjectProtocol {
    func convertFromMetadataToPreviewRect(rect: CGRect) -> CGRect
}

protocol FaceDetectorResultDelegate: AnyObject {
    func faceDetector(
        _ detector: FaceDetectorV2,
        didDetectFace faceGeometry: FaceGeometryData,
        withFaceQuality faceQuality: Float,
        selfieQuality: SelfieQualityData,
        brightness: Int
    )
    func faceDetector(_ detector: FaceDetectorV2, didFailWithError error: Error)
}

class FaceDetectorV2: NSObject {
    private var selfieQualityModel: SelfieQualityDetector?

    private let cropSize = (width: 120, height: 120)
    private let faceMovementThreshold: CGFloat = 0.15

    private var sequenceHandler = VNSequenceRequestHandler()

    weak var viewDelegate: FaceDetectorViewDelegate?
    weak var resultDelegate: FaceDetectorResultDelegate?

    // private let visionQueue = DispatchQueue(label: "com.smileidentity.ios.visionQueue")

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
                self.resultDelegate?.faceDetector(self, didFailWithError: FaceDetectorError.noFaceDetected)
                return
            }

            let convertedBoundingBox =
                self.viewDelegate?.convertFromMetadataToPreviewRect(rect: faceObservation.boundingBox) ?? .zero
            let brightness = self.calculateBrightness(imageBuffer)

            guard let croppedImage = try self.cropImageToFace(imageBuffer, boundingBox: faceObservation.boundingBox)
            else {
                return
            }
            guard let convertedImage = croppedImage.pixelBuffer(width: cropSize.width, height: cropSize.height) else {
                return
            }
            let selfieQualityData = try self.selfieQualityRequest(imageBuffer: convertedImage)

            if #available(iOS 15.0, *) {
                let faceGeometryData = FaceGeometryData(
                    boundingBox: convertedBoundingBox,
                    roll: faceObservation.roll ?? 0.0,
                    yaw: faceObservation.yaw ?? 0.0,
                    pitch: faceObservation.pitch ?? 0.0,
                    direction: faceDirection(faceObservation: faceObservation)
                )
                self.resultDelegate?
                    .faceDetector(
                        self,
                        didDetectFace: faceGeometryData,
                        withFaceQuality: faceQualityObservation.faceCaptureQuality ?? 0.0,
                        selfieQuality: selfieQualityData,
                        brightness: brightness
                    )
            } else {
                // Fallback on earlier versions
            }
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
        _ imageBuffer: CVPixelBuffer,
        boundingBox: CGRect
    ) throws -> UIImage? {
        guard let image = UIImage(pixelBuffer: imageBuffer),
            let cgImage = image.cgImage
        else {
            return nil
        }

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
            return nil
        }

        return UIImage(cgImage: croppedImage)
    }

    private func calculateBrightness(_ imageBuffer: CVPixelBuffer) -> Int {
        guard let image = UIImage(pixelBuffer: imageBuffer),
            let cgImage = image.cgImage,
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
