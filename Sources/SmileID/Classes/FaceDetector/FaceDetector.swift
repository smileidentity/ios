import Foundation
import Vision
import CoreImage
import UIKit

class FaceDetector: NSObject {
    var sequenceHandler = VNSequenceRequestHandler()
    weak var viewDelegate: FaceDetectorDelegate?
    private var transpositionHistoryPoints = [CGPoint]()
    private var previousPixelBuffer: CVPixelBuffer?

    func detectFaces(imageBuffer: CVImageBuffer) {
        let detectCaptureQualityRequest = VNDetectFaceCaptureQualityRequest(
            completionHandler: detectedFaceQualityRequest
        )
        let detectFaceRectanglesRequest = VNDetectFaceRectanglesRequest(
            completionHandler: detectedFaceRectangles
        )

        // Use most recent models or fallback to older versions
        if #available(iOS 17.0, *) {
            detectCaptureQualityRequest.revision = VNDetectFaceCaptureQualityRequestRevision3
        } else if #available(iOS 14.0, *) {
            detectCaptureQualityRequest.revision = VNDetectFaceCaptureQualityRequestRevision2
        } else {
            detectCaptureQualityRequest.revision = VNDetectFaceCaptureQualityRequestRevision1
        }

        if #available(iOS 15.0, *) {
            detectFaceRectanglesRequest.revision = VNDetectFaceRectanglesRequestRevision3
            runSequenceHandler(
                with: [detectFaceRectanglesRequest, detectCaptureQualityRequest],
                imageBuffer: imageBuffer
            )
            return
        } else {
            detectFaceRectanglesRequest.revision = VNDetectFaceRectanglesRequestRevision2
        }
        runSequenceHandler(
            with: [detectFaceRectanglesRequest, detectCaptureQualityRequest],
            imageBuffer: imageBuffer
        )
    }

    func detect(pixelBuffer: CVPixelBuffer) {
        guard let previousBuffer = previousPixelBuffer else {
            previousPixelBuffer = pixelBuffer
            return
        }
        let registrationRequest = VNTranslationalImageRegistrationRequest(
            targetedCVPixelBuffer: pixelBuffer
        )
        runSequenceHandler(with: [registrationRequest], imageBuffer: previousBuffer)
        previousPixelBuffer = pixelBuffer
        detectFaces(imageBuffer: pixelBuffer)
    }

    func runSequenceHandler(with requests: [VNRequest],
                            imageBuffer: CVImageBuffer) {
        do {
            try sequenceHandler.perform(
                requests,
                on: imageBuffer,
                orientation: .leftMirrored
            )
        } catch {
            print(error.localizedDescription)
        }
    }
}

extension FaceDetector {
    func detectedFaceRectangles(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNFaceObservation],
              let viewDelegate = viewDelegate
        else {
            // model?.perform(action: .noFaceDetected)
            return
        }

        if results.count > 1 {
            // model?.perform(action: .multipleFacesDetected)
            return
        }
        guard let result = results.first, !result.boundingBox.isNaN else {
            // model?.perform(action: .noFaceDetected)
            return
        }
        let convertedBoundingBox = viewDelegate.convertFromMetadataToPreviewRect(
            rect: result.boundingBox
        )

        let faceObservationModel = FaceGeometryModel(
            boundingBox: convertedBoundingBox,
            roll: result.roll ?? 0,
            yaw: result.yaw ?? 0
        )
        // model?.perform(action: .faceObservationDetected(faceObservationModel))
    }

    func detectedFaceQualityRequest(request: VNRequest, error: Error?) {
//        guard let model = model else {
//            return
//        }

        guard let results = request.results as? [VNFaceObservation],
              let result = results.first
        else {
            // model.perform(action: .noFaceDetected)
            return
        }

        let faceQualityModel = FaceQualityModel(quality: result.faceCaptureQuality ?? 0)
        // model.perform(action: .faceQualityObservationDetected(faceQualityModel))
    }
}

extension CGRect {
    var isNaN: Bool {
        origin.x.isNaN || origin.y.isNaN || size.width.isNaN || size.height.isNaN
    }
}
