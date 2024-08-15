import Foundation
import Vision
import CoreImage
import UIKit

class FaceDetector: NSObject {
    var sequenceHandler = VNSequenceRequestHandler()

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
}
