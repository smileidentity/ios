import Foundation
import Vision
import CoreImage
import UIKit

class FaceDetector: NSObject {
    var sequenceHandler = VNSequenceRequestHandler()
    weak var viewDelegate: FaceDetectorDelegate?

    /// Run Face Capture quality and Face Bounding Box and roll/pitch/yaw tracking
    func detect(
        imageBuffer: CVPixelBuffer,
        completionHandler: @escaping VNRequestCompletionHandler
    ) throws {
        // Since we submit both requests at the same time, the response is a fused result
        let detectCaptureQualityRequest = VNDetectFaceCaptureQualityRequest(
            completionHandler: completionHandler
        )
        let detectFaceRectanglesRequest = VNDetectFaceRectanglesRequest(
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

        detectFaceRectanglesRequest.revision = if #available(iOS 15.0, *) {
            VNDetectFaceRectanglesRequestRevision3
        } else {
            VNDetectFaceRectanglesRequestRevision2
        }

        try sequenceHandler.perform(
            [detectFaceRectanglesRequest, detectCaptureQualityRequest],
            on: imageBuffer,
            orientation: .leftMirrored
        )
    }
}

extension CGRect {
    var isNaN: Bool {
        origin.x.isNaN || origin.y.isNaN || size.width.isNaN || size.height.isNaN
    }
}
