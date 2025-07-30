import AVFoundation
import Combine
import UIKit
import Vision

enum FaceDetectorError: Error {
  case unableToLoadSelfieModel
  case invalidSelfieModelOutput
  case noFaceDetected
  case multipleFacesDetected
  case unableToCropImage
}

protocol FaceDetectorViewDelegate: NSObjectProtocol {
  func convertFromMetadataToPreviewRect(rect: CGRect) -> CGRect
}

protocol FaceDetectorResultDelegate: AnyObject {
  func faceDetector(
    _ detector: EnhancedFaceDetector,
    didDetectFace faceGeometry: FaceGeometryData,
    withFaceQuality faceQuality: Float,
    brightness: Int
  )
  func faceDetector(
    _ detector: EnhancedFaceDetector,
    didFailWithError error: Error
  )
  func faceDetectorTrackingStateChanged(
    _ detector: EnhancedFaceDetector,
    state: FaceTrackingState
  )
  func faceDetectorTrackingDidReset(
    _ detector: EnhancedFaceDetector
  )
}

class EnhancedFaceDetector: NSObject {
  private let cropSize = (width: 120, height: 120)
  private let faceMovementThreshold: CGFloat = 0.15

  private var sequenceHandler = VNSequenceRequestHandler()
  private var faceTrackingManager: FaceTrackingManager
  private var isTrackingEnabled: Bool = false

  weak var viewDelegate: FaceDetectorViewDelegate?
  weak var resultDelegate: FaceDetectorResultDelegate?

  override init() {
    self.faceTrackingManager = FaceTrackingManager()
    super.init()
    self.faceTrackingManager.delegate = self
  }

  func enableFaceTracking(_ enabled: Bool) {
    isTrackingEnabled = enabled
    if !enabled {
      faceTrackingManager.resetTracking()
    }
  }

  /// Run Face Capture quality and Face Bounding Box and roll/pitch/yaw tracking
  func processImageBuffer(_ imageBuffer: CVPixelBuffer) {
    if isTrackingEnabled {
      processImageBufferWithTracking(imageBuffer)
    } else {
      processImageBufferWithoutTracking(imageBuffer)
    }
  }

  private func processImageBufferWithTracking(_ imageBuffer: CVPixelBuffer) {
    switch faceTrackingManager.trackingState {
    case .detecting:
      performInitialFaceDetection(imageBuffer)
    case .tracking:
      faceTrackingManager.processFrame(imageBuffer)
    case .lost, .reset:
      break
    }
  }

  private func processImageBufferWithoutTracking(_ imageBuffer: CVPixelBuffer) {
    let detectFaceRectanglesRequest = VNDetectFaceRectanglesRequest()
    let detectCaptureQualityRequest = VNDetectFaceCaptureQualityRequest()

    do {
      try sequenceHandler.perform(
        [detectFaceRectanglesRequest, detectCaptureQualityRequest],
        on: imageBuffer,
        orientation: .leftMirrored)
      guard let faceDetections = detectFaceRectanglesRequest.results,
            let faceQualityObservations = detectCaptureQualityRequest.results,
            let faceObservation = faceDetections.first,
            let faceQualityObservation = faceQualityObservations.first
      else {
        resultDelegate?.faceDetector(
          self, didFailWithError: FaceDetectorError.noFaceDetected)
        return
      }

      guard faceDetections.count == 1 else {
        resultDelegate?.faceDetector(self, didFailWithError: FaceDetectorError.multipleFacesDetected)
        return
      }

      let convertedBoundingBox =
        viewDelegate?.convertFromMetadataToPreviewRect(
          rect: faceObservation.boundingBox) ?? .zero

      let uiImage = UIImage(pixelBuffer: imageBuffer)
      let brightness = calculateBrightness(uiImage)

      let faceGeometryData: FaceGeometryData
      if #available(iOS 15.0, *) {
        faceGeometryData = FaceGeometryData(
          boundingBox: convertedBoundingBox,
          roll: faceObservation.roll ?? 0.0,
          yaw: faceObservation.yaw ?? 0.0,
          pitch: faceObservation.pitch ?? 0.0,
          direction: faceDirection(faceObservation: faceObservation))
      } else { // Fallback on earlier versions
        faceGeometryData = FaceGeometryData(
          boundingBox: convertedBoundingBox,
          roll: faceObservation.roll ?? 0.0,
          yaw: faceObservation.yaw ?? 0.0,
          pitch: 0.0,
          direction: faceDirection(faceObservation: faceObservation))
      }
      resultDelegate?
        .faceDetector(
          self,
          didDetectFace: faceGeometryData,
          withFaceQuality: faceQualityObservation.faceCaptureQuality ?? 0.0,
          brightness: brightness)
    } catch {
      resultDelegate?.faceDetector(self, didFailWithError: error)
    }
  }

  private func cropImageToFace(
    _ image: UIImage?
  ) throws -> CVPixelBuffer {
    guard let image, let cgImage = image.cgImage else {
      throw FaceDetectorError.unableToCropImage
    }

    let request = VNDetectFaceRectanglesRequest()
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

    try handler.perform([request])

    guard let results = request.results,
          let face = results.first
    else {
      throw FaceDetectorError.noFaceDetected
    }

    let boundingBox = face.boundingBox

    let size = CGSize(
      width: boundingBox.width * image.size.width,
      height: boundingBox.height * image.size.height)
    let origin = CGPoint(
      x: boundingBox.minX * image.size.width,
      y: (1 - boundingBox.minY) * image.size.height - size.height)

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

  private func calculateBrightness(_ image: UIImage?) -> Int {
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

  private func performInitialFaceDetection(_ imageBuffer: CVPixelBuffer) {
    let detectFaceRectanglesRequest = VNDetectFaceRectanglesRequest()
    let detectCaptureQualityRequest = VNDetectFaceCaptureQualityRequest()

    do {
      try sequenceHandler.perform(
        [detectFaceRectanglesRequest, detectCaptureQualityRequest],
        on: imageBuffer,
        orientation: .leftMirrored)
      guard let faceDetections = detectFaceRectanglesRequest.results,
            let faceQualityObservations = detectCaptureQualityRequest.results,
            let faceObservation = faceDetections.first,
            let faceQualityObservation = faceQualityObservations.first
      else {
        resultDelegate?.faceDetector(
          self, didFailWithError: FaceDetectorError.noFaceDetected)
        return
      }

      guard faceDetections.count == 1 else {
        resultDelegate?.faceDetector(self, didFailWithError: FaceDetectorError.multipleFacesDetected)
        return
      }

      faceTrackingManager.startTracking(with: faceObservation)
      processDetectedFace(faceObservation, faceQualityObservation, imageBuffer)
    } catch {
      resultDelegate?.faceDetector(self, didFailWithError: error)
    }
  }

  private func processDetectedFace(
    _ faceObservation: VNFaceObservation,
    _ faceQualityObservation: VNFaceObservation,
    _ imageBuffer: CVPixelBuffer
  ) {
    let convertedBoundingBox =
      viewDelegate?.convertFromMetadataToPreviewRect(
        rect: faceObservation.boundingBox) ?? .zero

    let uiImage = UIImage(pixelBuffer: imageBuffer)
    let brightness = calculateBrightness(uiImage)

    let faceGeometryData: FaceGeometryData
    if #available(iOS 15.0, *) {
      faceGeometryData = FaceGeometryData(
        boundingBox: convertedBoundingBox,
        roll: faceObservation.roll ?? 0.0,
        yaw: faceObservation.yaw ?? 0.0,
        pitch: faceObservation.pitch ?? 0.0,
        direction: faceDirection(faceObservation: faceObservation))
    } else { // Fallback on earlier versions
      faceGeometryData = FaceGeometryData(
        boundingBox: convertedBoundingBox,
        roll: faceObservation.roll ?? 0.0,
        yaw: faceObservation.yaw ?? 0.0,
        pitch: 0.0,
        direction: faceDirection(faceObservation: faceObservation))
    }
    resultDelegate?
      .faceDetector(
        self,
        didDetectFace: faceGeometryData,
        withFaceQuality: faceQualityObservation.faceCaptureQuality ?? 0.0,
        brightness: brightness)
  }
}

// MARK: - FaceTrackingDelegate

extension EnhancedFaceDetector: FaceTrackingDelegate {
  func faceTrackingStateChanged(_ state: FaceTrackingState) {
    resultDelegate?.faceDetectorTrackingStateChanged(self, state: state)
  }

  func faceTrackingDidFail(with error: FaceTrackingError) {
    switch error {
    case .multipleFacesDetected:
      resultDelegate?.faceDetector(self, didFailWithError: FaceDetectorError.multipleFacesDetected)
    case .noFaceDetected:
      resultDelegate?.faceDetector(self, didFailWithError: FaceDetectorError.noFaceDetected)
    case .trackingLost, .trackingConfidenceTooLow, .differentFaceDetected:
      resultDelegate?.faceDetector(self, didFailWithError: FaceDetectorError.noFaceDetected)
    }
  }

  func faceTrackingDidReset() {
    resultDelegate?.faceDetectorTrackingDidReset(self)
  }
}
