import AVFoundation
import Combine
import UIKit
import Vision

protocol FaceDetectorDelegate: NSObjectProtocol {
    func convertFromMetadataToPreviewRect(rect: CGRect) -> CGRect
}

class FaceDetectorV2: NSObject {
    private var selfieQualityModel: SelfieQualityDetector?

    private let cropSize = (width: 120, height: 120)
    private let faceMovementThreshold: CGFloat = 0.15

    var sequenceHandler = VNSequenceRequestHandler()
    var currentFrameBuffer: CVPixelBuffer?

    weak var selfieViewModel: SelfieViewModelV2?
    weak var viewDelegate: FaceDetectorDelegate?

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
    func detect(_ imageBuffer: CVPixelBuffer) {
        currentFrameBuffer = imageBuffer

        let detectFaceRectanglesRequest = VNDetectFaceRectanglesRequest(
            completionHandler: detectedFaceRectangles
        )

        let detectCaptureQualityRequest = VNDetectFaceCaptureQualityRequest(
            completionHandler: detectedFaceQualityRequest
        )

        do {
            try sequenceHandler.perform(
                [
                    detectFaceRectanglesRequest,
                    detectCaptureQualityRequest
                ],
                on: imageBuffer,
                orientation: .leftMirrored
            )
        } catch {
            selfieViewModel?.perform(action: .handleError(error))
        }

        do {
            guard let image = UIImage(pixelBuffer: imageBuffer) else {
                return
            }
            guard let croppedImage = try cropToFace(image: image) else {
                return
            }
            guard let convertedImage = croppedImage.pixelBuffer(width: cropSize.width, height: cropSize.height) else {
                return
            }
            selfieQualityRequest(imageBuffer: convertedImage)
        } catch {
            selfieViewModel?.perform(action: .handleError(error))
        }
    }

    func selfieQualityRequest(imageBuffer: CVPixelBuffer) {
        guard let selfieViewModel,
                let selfieQualityModel  else { return }
        do {
            let input = SelfieQualityDetectorInput(conv2d_193_input: imageBuffer)

            let prediction = try selfieQualityModel.prediction(input: input)
            let output = prediction.Identity

            guard output.shape.count == 2,
                  output.shape[0] == 1,
                  output.shape[1] == 2 else {
                return
            }

            let passScore = output[0].floatValue
            let failScore = output[1].floatValue

            let selfieQualityModel = SelfieQualityModel(
                failed: failScore,
                passed: passScore
            )
            selfieViewModel.perform(action: .selfieQualityObservationDetected(selfieQualityModel))
        } catch {
            selfieViewModel.perform(action: .handleError(error))
        }
    }

    private func cropToFace(image: UIImage) throws -> UIImage? {
        guard let cgImage = image.cgImage else {
            return nil
        }

        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        try handler.perform([request])

        guard let results = request.results,
              let face = results.first else {
            return nil
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
            return nil
        }

        return UIImage(cgImage: croppedImage)
    }
}

// MARK: - Private methods
extension FaceDetectorV2 {
    func detectedFaceRectangles(request: VNRequest, error: Error?) {
        guard let selfieViewModel = selfieViewModel,
              let viewDelegate = viewDelegate else { return }

        guard let results = request.results as? [VNFaceObservation],
                let result = results.first else {
            selfieViewModel.perform(action: .noFaceDetected)
            return
        }

        let convertedBoundingBox = viewDelegate.convertFromMetadataToPreviewRect(rect: result.boundingBox)

        if #available(iOS 15.0, *) {
            let faceObservationModel = FaceGeometryModel(
                boundingBox: convertedBoundingBox,
                roll: result.roll ?? 0.0,
                yaw: result.yaw ?? 0.0,
                pitch: result.pitch ?? 0.0,
                direction: faceDirection(faceObservation: result)
            )
            selfieViewModel.perform(action: .faceObservationDetected(faceObservationModel))
        } else {
            // Fallback on earlier versions
        }
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

    func detectedFaceQualityRequest(request: VNRequest, error: Error?) {
        guard let selfieViewModel = selfieViewModel else { return }

        guard let results = request.results as? [VNFaceObservation],
                let result = results.first else {
            selfieViewModel.perform(action: .noFaceDetected)
            return
        }

        let faceQualityModel = FaceQualityModel(
            quality: result.faceCaptureQuality ?? 0.0
        )
        selfieViewModel.perform(action: .faceQualityObservationDetected(faceQualityModel))
    }
}
