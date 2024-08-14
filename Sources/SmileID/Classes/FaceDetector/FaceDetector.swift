import Foundation
import Vision
import CoreImage
import UIKit

enum FaceDirection {
    case left
    case right
    case none
}

class FaceDetector: NSObject {
    var sequenceHandler = VNSequenceRequestHandler()
    
    private var faceMovementThreshold: CGFloat = 0.15
    private var lastYawAngle: CGFloat = 0.0

    /// Run Face Capture quality and Face Bounding Box and roll/pitch/yaw tracking
    func detect(
        imageBuffer: CVPixelBuffer,
        completionHandler: @escaping VNRequestCompletionHandler
    ) throws {
        let detectCaptureQualityRequest = VNDetectFaceCaptureQualityRequest(
            completionHandler: completionHandler
        )

        // Use most recent models or fallback to older versions
        detectCaptureQualityRequest.revision = if #available(iOS 17.0, *) {
            VNDetectFaceCaptureQualityRequestRevision3
        } else if #available(iOS 14.0, *) {
            VNDetectFaceCaptureQualityRequestRevision2
        } else {
            VNDetectFaceCaptureQualityRequestRevision1
        }

        try sequenceHandler.perform(
            [detectCaptureQualityRequest],
            on: imageBuffer,
            orientation: .leftMirrored
        )
    }

    func detectFaceMovement(faceObservation: VNFaceObservation) -> FaceDirection {
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
