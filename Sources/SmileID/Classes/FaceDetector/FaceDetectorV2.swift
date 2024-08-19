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
    var currentFrameBuffer: CVPixelBuffer?

    /// Run Face Capture quality and Face Bounding Box and roll/pitch/yaw tracking
    func detect(imageBuffer: CVPixelBuffer) {
        currentFrameBuffer = imageBuffer

        let detectFaceRectanglesRequest = VNDetectFaceRectanglesRequest(
            completionHandler: detectedFaceRectangles
        )

        let detectCaptureQualityRequest = VNDetectFaceCaptureQualityRequest(
            completionHandler: detectedFaceQualityRequest
        )

//        let coreMLModel = createImageClassifier()
//        let imageClassificationRequest = VNCoreMLRequest(model: coreMLModel, completionHandler: detectedSelfieQuality)

        do {
            try sequenceHandler.perform(
                [
                    detectFaceRectanglesRequest,
                    detectCaptureQualityRequest
                    // imageClassificationRequest
                ],
                on: imageBuffer,
                orientation: .leftMirrored
            )
        } catch {
            model?.perform(action: .handleError(error))
        }

        do {
            guard let image = UIImage(pixelBuffer: imageBuffer) else {
                return
            }
            guard let croppedImage = try cropToFace(image: image) else {
                return
            }
            guard let convertedImage = croppedImage.pixelBuffer(width: 120, height: 120) else {
                return
            }
            selfieQualityRequest(imageBuffer: convertedImage)
        } catch {
            print(error.localizedDescription, error)
        }
    }

    func selfieQualityRequest(imageBuffer: CVPixelBuffer) {
        // let selfieQualityRequest = VNImageRequestHandler(cvPixelBuffer: imageBuffer)
        // let model = createImageClassifier()
        // let imageClassificationRequest = VNCoreMLRequest(model: model, completionHandler: detectedSelfieQuality)

        guard let model = model else { return }

        do {
            let modelConfiguration = MLModelConfiguration()
            let coreMLModel = try SelfieQualityDetector(configuration: modelConfiguration)

            let input = SelfieQualityDetectorInput(conv2d_193_input: imageBuffer)

            let prediction = try coreMLModel.prediction(input: input)
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
            model.perform(action: .selfieQualityObservationDetected(selfieQualityModel))
        } catch {
            print(error.localizedDescription, error)
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

    private func createImageClassifier() -> VNCoreMLModel {
        let defaultConfig = MLModelConfiguration()
        let imageClassifierWrapper = try? SelfieQualityDetector(configuration: defaultConfig)
        guard let imageClassifier = imageClassifierWrapper else {
            fatalError("Failed to create an image classifier model instance.")
        }

        let imageClassifierModel = imageClassifier.model
        
        guard let imageClassifierVisionModel = try? VNCoreMLModel(for: imageClassifierModel) else {
            fatalError("Failed to create a `VNCoreMLModel` instance.")
        }

        return imageClassifierVisionModel
    }
}

// MARK: - Private methods
extension FaceDetectorV2 {
    func detectedFaceRectangles(request: VNRequest, error: Error?) {
        guard let model = model,
              let imageBuffer = currentFrameBuffer else { return }

        guard let results = request.results as? [VNFaceObservation],
                let result = results.first else {
            model.perform(action: .noFaceDetected)
            return
        }

        // let convertedBoundingBox = viewDelegate.convertFromMetadataToPreviewRect(rect: result.boundingBox)
        let convertedBoundingBox = convertBoundingBox(
            faceObservation: result,
            bufferImage: imageBuffer
        )

        if #available(iOS 15.0, *) {
            let faceObservationModel = FaceGeometryModel(
                boundingBox: convertedBoundingBox,
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

    private func convertBoundingBox(
        faceObservation: VNFaceObservation,
        bufferImage: CVPixelBuffer
    ) -> CGRect {
        guard let image = UIImage(pixelBuffer: bufferImage) else {
            return .zero
        }
        let boundingBox = faceObservation.boundingBox
        let size = CGSize(
            width: boundingBox.width * image.size.width,
            height: boundingBox.height * image.size.height
        )
        let origin = CGPoint(
            x: boundingBox.minX * image.size.width,
            y: (1 - boundingBox.minY) * image.size.height - size.height
        )

        let faceRect = CGRect(origin: origin, size: size)
        return faceRect
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
        guard let model = model else { return }

        guard let results = request.results as? [VNFaceObservation],
                let result = results.first else {
            model.perform(action: .noFaceDetected)
            return
        }

        let faceQualityModel = FaceQualityModel(
            quality: result.faceCaptureQuality ?? 0.0
        )
        model.perform(action: .faceQualityObservationDetected(faceQualityModel))
    }

    func detectedSelfieQuality(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNCoreMLFeatureValueObservation] else {
            print("VNRequest produced the wrong result type: \(type(of: request.results)).")
            return
        }
        observations.first?.featureValue
    }
}
