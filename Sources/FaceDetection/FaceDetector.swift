import Foundation
import Vision
import CoreImage

class FaceDetector {
    var sequenceHandler = VNSequenceRequestHandler()
    weak var model: SelfieCaptureViewModel?
    var viewDelegate: FaceDetectorDelegate?
    private let maximumHistoryLength = 15
    private var transpositionHistoryPoints = [CGPoint]()
    private var previousPixelBuffer: CVPixelBuffer?

    func detectFaces(imageBuffer: CVImageBuffer) {
        let detectCaptureQualityRequest = VNDetectFaceCaptureQualityRequest(completionHandler: detectedFaceQualityRequest)
        let detectFaceRectanglesRequest = VNDetectFaceRectanglesRequest(completionHandler: detectedFaceRectangles)
        // Use most recent models or fallback to older versions
        if #available(iOS 14.0, *) {
            detectCaptureQualityRequest.revision = VNDetectFaceCaptureQualityRequestRevision2
        } else {
            detectCaptureQualityRequest.revision = VNDetectFaceCaptureQualityRequestRevision1
        }

        if #available(iOS 15.0, *) {
            detectFaceRectanglesRequest.revision = VNDetectFaceRectanglesRequestRevision3
            runSequenceHandler(with: [detectFaceRectanglesRequest, detectCaptureQualityRequest],
                               imageBuffer: imageBuffer)
            return
        } else {
            detectFaceRectanglesRequest.revision = VNDetectFaceRectanglesRequestRevision2
        }
        runSequenceHandler(with: [detectFaceRectanglesRequest, detectCaptureQualityRequest],
                           imageBuffer: imageBuffer)
    }

    func isSceneStable() -> Bool {
        if transpositionHistoryPoints.count == maximumHistoryLength {
            // Calculate the moving average.
            var movingAverage: CGPoint = CGPoint.zero
            for currentPoint in transpositionHistoryPoints {
                movingAverage.x += currentPoint.x
                movingAverage.y += currentPoint.y
            }
            let distance = abs(movingAverage.x) + abs(movingAverage.y)
            if distance < 20 {
                return true
            }
        }
        return false
    }

    func detect(pixelBuffer: CVPixelBuffer) {
        guard let previousBuffer = previousPixelBuffer else {
            previousPixelBuffer = pixelBuffer
            self.resetTranspositionHistory()
            return
        }
        let registrationRequest = VNTranslationalImageRegistrationRequest(targetedCVPixelBuffer: pixelBuffer)
        runSequenceHandler(with: [registrationRequest], imageBuffer: previousBuffer)

        previousPixelBuffer = pixelBuffer
        if let results = registrationRequest.results {
            if let alignmentObservation = results.first {
                let alignmentTransform = alignmentObservation.alignmentTransform
                self.recordTransposition(CGPoint(x: alignmentTransform.tx, y: alignmentTransform.ty))
            }
        }

        if isSceneStable() {
            detectFaces(imageBuffer: pixelBuffer)
        } else {
            model?.perform(action: .sceneUnstable)
        }
    }

    func recordTransposition(_ point: CGPoint) {
        transpositionHistoryPoints.append(point)
        if transpositionHistoryPoints.count > maximumHistoryLength {
            transpositionHistoryPoints.removeFirst()
        }
    }

    func resetTranspositionHistory() {
        transpositionHistoryPoints.removeAll()
    }

    func detectSmile(imageBuffer: CVImageBuffer) -> Bool {
        let image = CIImage(cvImageBuffer: imageBuffer)
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let smileDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: options)!
        let faces = smileDetector.features(in: image)
        print("Face count \(faces.count)")
        if let face = faces.first as? CIFaceFeature {
            if face.leftEyeClosed {
                print("left eye closed")
            }
            if face.hasSmile {
                print("is smilling")
                return true
            }
        }
        return false
    }

    func runSequenceHandler(with requests: [VNRequest],
                            imageBuffer: CVImageBuffer) {
        do {
            try sequenceHandler.perform(requests,
                                        on: imageBuffer,
                                        orientation: .upMirrored)
        } catch {
            print(error.localizedDescription)
        }
    }
}

extension FaceDetector {
    func detectedFaceRectangles(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNFaceObservation], let viewDelegate = viewDelegate else {
            model?.perform(action: .noFaceDetected)
            return
        }

        if results.count > 1 {
            model?.perform(action: .multipleFacesDetected)
            return
        }
        guard let result = results.first else {
            model?.perform(action: .noFaceDetected)
            return
        }
        let convertedBoundingBox = viewDelegate.convertFromMetadataToPreviewRect(rect: result.boundingBox)

        let faceObservationModel = FaceGeometryModel(
            boundingBox: convertedBoundingBox,
            roll: result.roll ?? 0,
            yaw: result.yaw ?? 0
        )
        model?.perform(action: .faceObservationDetected(faceObservationModel))
    }

    func detectedFaceQualityRequest(request: VNRequest, error: Error?) {
        guard let model = model else {
            return
        }

        guard let results = request.results as? [VNFaceObservation],
              let result = results.first else {
            model.perform(action: .noFaceDetected)
            return
        }

        let faceQualityModel = FaceQualityModel(quality: result.faceCaptureQuality ?? 0)
        model.perform(action: .faceQualityObservationDetected(faceQualityModel))
    }
}
