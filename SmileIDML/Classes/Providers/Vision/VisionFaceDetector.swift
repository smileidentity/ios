import CoreVideo
import Foundation
@preconcurrency import Vision

final class VisionFaceDetector: FaceDetecting {
  private let configuration: ModelConfiguration
  private let processingQueue = DispatchQueue(
    label: "com.smileid.vision.face",
    qos: .userInitiated
  )

  init(configuration: ModelConfiguration) {
    self.configuration = configuration
  }

  func detectFaces(
    in buffer: CVPixelBuffer
  ) async throws -> [FaceDetectionResult] {
    try await withCheckedThrowingContinuation { continuation in
      let request = VNDetectFaceRectanglesRequest { request, error in
        if let error {
          continuation.resume(throwing: ModelError.inferenceError(underlying: error))
          return
        }

        guard let observations = request.results as? [VNFaceObservation] else {
          continuation.resume(returning: [])
          return
        }

        let results = observations.map {
          self.convertToResult($0)
        }
        continuation.resume(returning: results)
      }

      // Specify revision for consistent behaviour
      if #available(iOS 17.0, *) {
        request.revision = VNClassifyImageRequestRevision2
      } else {
        request.revision = VNClassifyImageRequestRevision1
      }

      let handler = VNImageRequestHandler(cvPixelBuffer: buffer, options: [:])

      processingQueue.async {
        do {
          try handler.perform([request])
        } catch {
          continuation.resume(throwing: ModelError.inferenceError(underlying: error))
        }
      }
    }
  }

  private func convertToResult(
    _ observation: VNFaceObservation
  ) -> FaceDetectionResult {
    let normalizedBoundingBox = normalizeBoundingBox(observation.boundingBox)

    if #available(iOS 15.0, *) {
      FaceDetectionResult(
        boundingBox: normalizedBoundingBox,
        landmarks: convertLandmarks(observation.landmarks),
        trackingID: observation.uuid.hashValue,
        roll: observation.roll?.floatValue,
        pitch: observation.pitch?.floatValue,
        yaw: observation.yaw?.floatValue,
        confidence: observation.confidence
      )
    } else {
      FaceDetectionResult(
        boundingBox: normalizedBoundingBox,
        landmarks: convertLandmarks(observation.landmarks),
        trackingID: observation.uuid.hashValue,
        roll: observation.roll?.floatValue,
        pitch: nil,
        yaw: observation.yaw?.floatValue,
        confidence: observation.confidence
      )
    }
  }

  private func convertLandmarks(_ landmarks: VNFaceLandmarks2D?) -> FaceLandmarks? {
    guard let landmarks else { return nil }
    // Convert vision landmarks to our model
    return FaceLandmarks(
      leftEye: landmarks.leftEye?.normalizedPoints.first ?? .zero,
      rightEye: landmarks.rightEye?.normalizedPoints.first ?? .zero,
      nose: landmarks.nose?.normalizedPoints.first ?? .zero,
      mouth: landmarks.innerLips?.normalizedPoints.first ?? .zero
    )
  }

  private func normalizeBoundingBox(_ boundingBox: CGRect) -> CGRect {
    // Vision reports bounding boxes using a bottom-left origin; flip them to our top-left coordinate space.
    CGRect(
      x: boundingBox.origin.x,
      y: 1 - boundingBox.origin.y - boundingBox.height,
      width: boundingBox.width,
      height: boundingBox.height
    )
  }
}
