import Foundation
import Vision
import CoreImage

class FaceDetector {
    var sequenceHandler = VNSequenceRequestHandler()
    weak var model: SelfieCaptureViewModel?
    weak var viewDelegate: FaceDetectorDelegate?
    private let maximumHistoryLength = 20
    private var transpositionHistoryPoints = [CGPoint]()
    private var previousPixelBuffer: CVPixelBuffer?
    private var eyeAspectRatioHistory: [CGPoint] = []
    private var mouthAspectRatioHistory: [CGFloat] = []
    private let maximumAspectRatioHistoryLength = 10

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
            faceLandmarksChecks(pixelBuffer: pixelBuffer)
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

    func recordEyeAspectRatio(_ ratio: CGPoint) {
        if eyeAspectRatioHistory.count >= maximumAspectRatioHistoryLength {
            eyeAspectRatioHistory.removeFirst()
        }
        eyeAspectRatioHistory.append(ratio)
    }

    func recordMouthAspectRatio(_ ratio: CGFloat) {
        if mouthAspectRatioHistory.count >= maximumAspectRatioHistoryLength {
            mouthAspectRatioHistory.removeFirst()
        }
        mouthAspectRatioHistory.append(ratio)
    }

    func averageEyeAspectRatioChange() -> CGFloat {
        guard eyeAspectRatioHistory.count > 1 else { return 0 }

        var changeSum: CGFloat = 0
        for i in 1..<eyeAspectRatioHistory.count {
            let previousRatio = eyeAspectRatioHistory[i-1]
            let currentRatio = eyeAspectRatioHistory[i]
            let changeInRatio = abs(currentRatio.x - previousRatio.x) + abs(currentRatio.y - previousRatio.y)
            changeSum += changeInRatio
        }

        return changeSum / CGFloat(eyeAspectRatioHistory.count - 1)
    }

    fileprivate func isUserAlive() -> Bool {
        let averageEyeChange = self.averageEyeAspectRatioChange()
        let averageMouthChange = self.averageMouthAspectRatioChange()
        if averageEyeChange > 0.05 || averageMouthChange > 0.05 {
            return true
        }

        return false
    }

    func faceLandmarksChecks(pixelBuffer: CVPixelBuffer) {
        var alive = false
        // Create a face landmarks request.
        let faceLandmarksRequest = VNDetectFaceLandmarksRequest { request, error in
            if let error = error {
                print("Failed to detect face landmarks: \(error)")
                return
            }

            guard let results = request.results as? [VNFaceObservation] else {
                self.model?.perform(action: .noFaceDetected)
                return
            }

            // If multiple faces are detected, we can't be sure which one is the user.
            if results.count > 1 {
                self.model?.perform(action: .multipleFacesDetected)
                return
            }

            guard let face = results.first, let landmarks = face.landmarks else {
                self.model?.perform(action: .noFaceDetected)
                return
            }

            guard let innerLips = landmarks.outerLips else {
                return
            }

            let mouthAspectRatio = self.euclideanDistance(innerLips.normalizedPoints[2], innerLips.normalizedPoints[10]) /
            self.euclideanDistance(innerLips.normalizedPoints[4], innerLips.normalizedPoints[8])

            // Record the mouth aspect ratio.
            self.recordMouthAspectRatio(mouthAspectRatio)

            guard let leftEye = landmarks.leftEye, let rightEye = landmarks.rightEye else {
                return
            }

            let leftEyeAspectRatio = self.euclideanDistance(leftEye.normalizedPoints[1], leftEye.normalizedPoints[5]) /
            self.euclideanDistance(leftEye.normalizedPoints[2], leftEye.normalizedPoints[4])
            let rightEyeAspectRatio = self.euclideanDistance(rightEye.normalizedPoints[1], rightEye.normalizedPoints[5]) /
            self.euclideanDistance(rightEye.normalizedPoints[2], rightEye.normalizedPoints[4])

            // Record the eye aspect ratios.
            self.recordEyeAspectRatio(CGPoint(x: leftEyeAspectRatio, y: rightEyeAspectRatio))

            print("Is the user alive? \(self.isUserAlive())")
        }

        // Perform the request.
        runSequenceHandler(with: [faceLandmarksRequest], imageBuffer: pixelBuffer)

    }

    func averageMouthAspectRatioChange() -> CGFloat {
        guard mouthAspectRatioHistory.count > 1 else { return 0 }

        var changeSum: CGFloat = 0
        for i in 1..<mouthAspectRatioHistory.count {
            let previousRatio = mouthAspectRatioHistory[i-1]
            let currentRatio = mouthAspectRatioHistory[i]
            let changeInRatio = abs(currentRatio - previousRatio)
            changeSum += changeInRatio
        }

        return changeSum / CGFloat(mouthAspectRatioHistory.count - 1)
    }


    func resetTranspositionHistory() {
        transpositionHistoryPoints.removeAll()
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

    func euclideanDistance(_ point1: CGPoint, _ point2: CGPoint) -> CGFloat {
        let xDistance = point2.x - point1.x
        let yDistance = point2.y - point1.y
        return sqrt(xDistance * xDistance + yDistance * yDistance)
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
        guard let result = results.first, !result.boundingBox.isNaN else {
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

extension CGRect {
    var isNaN: Bool {
        return origin.x.isNaN || origin.y.isNaN || size.width.isNaN || size.height.isNaN
    }
}
