import Foundation
import Vision
import CoreImage
import UIKit

class FaceDetector: NSObject {
    var sequenceHandler = VNSequenceRequestHandler()
    weak var viewDelegate: FaceDetectorDelegate?
    private var transpositionHistoryPoints = [CGPoint]()
    private var previousPixelBuffer: CVPixelBuffer?
    var delegate: FaceDetectionDelegate?

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

    func runSequenceHandler(with requests: [VNRequest], imageBuffer: CVImageBuffer) {
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
            delegate?.onFaceObservation(observation: nil)
            return
        }

        if results.count > 1 {
            delegate?.onMultipleFaces()
            print("FaceDetector - Multiple faces detected")
            return
        }
        guard let result = results.first, !result.boundingBox.isNaN else {
            print("FaceDetector - No face detected")
            delegate?.onFaceObservation(observation: nil)
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
        delegate?.onFaceObservation(observation: faceObservationModel)
        print("FaceDetector - Face observation detected: \(faceObservationModel)")
    }

    func detectedFaceQualityRequest(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNFaceObservation],
              let result = results.first
        else {
            delegate?.onFaceObservation(observation: nil)
            print("FaceDetector - No face detected")
            return
        }

        let faceQuality = result.faceCaptureQuality ?? 0
        print("FaceDetector - Face Quality: \(faceQuality)")
    }
}

extension CGRect {
    var isNaN: Bool {
        origin.x.isNaN || origin.y.isNaN || size.width.isNaN || size.height.isNaN
    }
}
