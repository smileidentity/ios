import AVFoundation
import Combine
import Vision

protocol FaceDetectorDelegate: NSObjectProtocol {
    func convertFromMetadataToPreviewRect(rect: CGRect) -> CGRect
}

class FaceDetectorV2: NSObject {
    private let faceMovementThreshold: CGFloat = 0.15
    
    var sequenceHandler = VNSequenceRequestHandler()
    weak var model: SelfieViewModelV2?

    /// Run Face Capture quality and Face Bounding Box and roll/pitch/yaw tracking
    func detect(imageBuffer: CVPixelBuffer) {
        let detectFaceRectanglesRequest = VNDetectFaceRectanglesRequest(completionHandler: detectedFaceRectangles)

        do {
            try sequenceHandler.perform([detectFaceRectanglesRequest], on: imageBuffer, orientation: .leftMirrored)
        } catch {
            model?.perform(action: .handleError(error))
        }
    }
}

// MARK: - Private methods
extension FaceDetectorV2 {
    func detectedFaceRectangles(request: VNRequest, error: Error?) {
        guard let model = model else { return }

        guard let results = request.results as? [VNFaceObservation],
                let result = results.first else {
            model.perform(action: .noFaceDetected)
            return
        }

        // let convertedBoundingBox = viewDelegate.convertFromMetadataToPreviewRect(rect: result.boundingBox)

        if #available(iOS 15.0, *) {
            let faceObservationModel = FaceGeometryModel(
                boundingBox: .zero, // Change this later.
                roll: result.roll ?? 0.0,
                yaw: result.yaw ?? 0.0,
                pitch: result.pitch ?? 0.0,
                direction: faceDirection(faceObservation: result)
            )
            model.perform(action: .faceObservationDetected(faceObservationModel))
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

}
