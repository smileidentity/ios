import AVFoundation
import Combine
import UIKit
import Vision

enum FaceDetectorError: Error {
    case unableToLoadSelfieModel
    case invalidSelfieModelOutput
    case noFaceDetected
    case unableToCropImage
}

protocol FaceDetectorProtocol {
    var viewDelegate: FaceDetectorViewDelegate? { get set }
    var resultDelegate: FaceDetectorResultDelegate? { get set }
    func processImageBuffer(_ imageBuffer: CVPixelBuffer)
}

protocol FaceDetectorViewDelegate: AnyObject {
    func convertFromMetadataToPreviewRect(rect: CGRect) -> CGRect
}

protocol FaceDetectorResultDelegate: AnyObject {
    func faceDetector(
        _ detector: FaceDetectorV2,
        didDetectFace faceGeometry: FaceGeometryData,
        withFaceQuality faceQuality: Float,
        selfieQuality: SelfieQualityData,
        brightness: Int
    )
    func faceDetector(_ detector: FaceDetectorV2, didFailWithError error: Error)
}

protocol SelfieQualityDetectorProtocol {
    func predict(imageBuffer: CVPixelBuffer) throws -> SelfieQualityData
}

protocol VNSequenceRequestHandlerProtocol {
    func perform(
        _ requests: [VNRequest],
        on pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation
    ) throws
}

extension VNSequenceRequestHandler: VNSequenceRequestHandlerProtocol {}

protocol VNImageRequestHandlerProtocol {
    func perform(_ requests: [VNRequest]) throws
}

extension VNImageRequestHandler: VNImageRequestHandlerProtocol {}

class FaceDetectorV2: NSObject {
    private let selfieQualityDetector: SelfieQualityDetectorProtocol

    private let cropSize = (width: 120, height: 120)
    private let faceMovementThreshold: CGFloat = 0.15

    private let sequenceHandler: VNSequenceRequestHandlerProtocol
    private var imageRequestHandler: VNImageRequestHandlerProtocol?
    var VNDetectFaceRectanglesRequestClass = VNDetectFaceRectanglesRequest.self
    var VNDetectFaceCaptureQualityRequestClass = VNDetectFaceCaptureQualityRequest.self

    weak var viewDelegate: FaceDetectorViewDelegate?
    weak var resultDelegate: FaceDetectorResultDelegate?

    init(
        sequenceHandler: VNSequenceRequestHandlerProtocol = VNSequenceRequestHandler(),
        imageRequestHandler: VNImageRequestHandlerProtocol? = nil,
        selfieQualityDetector: SelfieQualityDetectorProtocol = SelfieQualityDetectorWrapper()
    ) {
        self.sequenceHandler = sequenceHandler
        self.imageRequestHandler = imageRequestHandler
        self.selfieQualityDetector = selfieQualityDetector
    }

    /// Run Face Capture quality and Face Bounding Box and roll/pitch/yaw tracking
    func processImageBuffer(_ imageBuffer: CVPixelBuffer) {
        let detectFaceRectanglesRequest = VNDetectFaceRectanglesRequestClass.init()
        let detectCaptureQualityRequest = VNDetectFaceCaptureQualityRequestClass.init()

        #if targetEnvironment(simulator)
            detectFaceRectanglesRequest.usesCPUOnly = true
            detectCaptureQualityRequest.usesCPUOnly = true
        #endif

        do {
            try sequenceHandler.perform(
                [detectFaceRectanglesRequest, detectCaptureQualityRequest],
                on: imageBuffer,
                orientation: .leftMirrored
            )
            guard let faceDetections = detectFaceRectanglesRequest.results,
                let faceQualityObservations = detectCaptureQualityRequest.results,
                let faceObservation = faceDetections.first,
                let faceQualityObservation = faceQualityObservations.first
            else {
                self.resultDelegate?.faceDetector(
                    self, didFailWithError: FaceDetectorError.noFaceDetected)
                return
            }

            let convertedBoundingBox =
                self.viewDelegate?.convertFromMetadataToPreviewRect(
                    rect: faceObservation.boundingBox) ?? .zero

            let uiImage = UIImage(pixelBuffer: imageBuffer)
            let brightness = self.calculateBrightness(uiImage)
            let croppedImage = try self.cropImageToFace(uiImage)

            let selfieQualityData = try self.selfieQualityDetector.predict(imageBuffer: croppedImage)

            if #available(iOS 15.0, *) {
                let faceGeometryData = FaceGeometryData(
                    boundingBox: convertedBoundingBox,
                    roll: faceObservation.roll ?? 0.0,
                    yaw: faceObservation.yaw ?? 0.0,
                    pitch: faceObservation.pitch ?? 0.0,
                    direction: faceDirection(faceObservation: faceObservation)
                )
                self.resultDelegate?
                    .faceDetector(
                        self,
                        didDetectFace: faceGeometryData,
                        withFaceQuality: faceQualityObservation.faceCaptureQuality ?? 0.0,
                        selfieQuality: selfieQualityData,
                        brightness: brightness
                    )
            } else {
                // Fallback on earlier versions
            }
        } catch {
            self.resultDelegate?.faceDetector(self, didFailWithError: error)
        }
    }

    func cropImageToFace(
        _ image: UIImage?
    ) throws -> CVPixelBuffer {
        guard let image, let cgImage = image.cgImage else {
            throw FaceDetectorError.unableToCropImage
        }

        let request = VNDetectFaceRectanglesRequestClass.init()
        #if targetEnvironment(simulator)
            request.usesCPUOnly = true
        #endif
        if imageRequestHandler == nil {
            imageRequestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        }

        try imageRequestHandler?.perform([request])

        guard let results = request.results,
            let face = results.first
        else {
            throw FaceDetectorError.noFaceDetected
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

        guard let croppedCGImage = cgImage.cropping(to: faceRect) else {
            throw FaceDetectorError.unableToCropImage
        }

        let croppedImage = UIImage(cgImage: croppedCGImage)
        guard
            let resizedImage = croppedImage.pixelBuffer(
                width: cropSize.width, height: cropSize.height)
        else {
            throw FaceDetectorError.unableToCropImage
        }

        return resizedImage
    }

    func calculateBrightness(_ image: UIImage?) -> Int {
        guard let image, let cgImage = image.cgImage,
            let imageData = cgImage.dataProvider?.data,
            let dataPointer = CFDataGetBytePtr(imageData)
        else {
            return 0
        }

        let bytesPerPixel = cgImage.bitsPerPixel / cgImage.bitsPerComponent
        let dataLength = CFDataGetLength(imageData)
        var result = 0.0
        for index in stride(from: 0, to: dataLength, by: bytesPerPixel) {
            let red = dataPointer[index]
            let green = dataPointer[index + 1]
            let blue = dataPointer[index + 2]
            result += 0.299 * Double(red) + 0.587 * Double(green) + 0.114 * Double(blue)
        }
        let pixelsCount = dataLength / bytesPerPixel
        let brightness = Int(result) / pixelsCount
        return brightness
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

extension FaceDetectorV2: FaceDetectorProtocol {}
