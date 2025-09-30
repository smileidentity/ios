import Foundation
@preconcurrency import Vision

final class VisionFaceQualityAnalyzer: FaceQualityAnalyzing {
  private let configuration: ModelConfiguration
  private let processingQueue = DispatchQueue(
    label: "com.smileid.vision.quality",
    qos: .userInitiated
  )

  init(configuration: ModelConfiguration) {
    self.configuration = configuration
  }

  func analyzeFaceQuality(
    in buffer: CVPixelBuffer,
    face _: FaceDetectionResult
  ) async throws -> FaceQualityResult {
    // Use VNDetectFaceQualityRequest for quality assessment
    try await withCheckedThrowingContinuation { continuation in
      let request = VNDetectFaceCaptureQualityRequest { request, error in
        if let error {
          continuation.resume(throwing: ModelError.inferenceError(underlying: error))
          return
        }

        guard let observations = request.results as? [VNFaceObservation],
              let observation = observations.first else {
          continuation.resume(throwing: ModelError.invalidInput)
          return
        }

        let result = self.buildQualityResult(from: observation, buffer: buffer)
        continuation.resume(returning: result)
      }

      // Always specify revision
      if #available(iOS 17.0, *) {
        request.revision = VNDetectFaceCaptureQualityRequestRevision3
      } else if #available(iOS 14.0, *) {
        request.revision = VNDetectFaceCaptureQualityRequestRevision2
      } else {
        request.revision = VNDetectFaceCaptureQualityRequestRevision1
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

  private func buildQualityResult(
    from observation: VNFaceObservation,
    buffer: CVPixelBuffer
  ) -> FaceQualityResult {
    let captureQuality = observation.faceCaptureQuality ?? 0.0
    let brightness = calculateBrightness(buffer, region: observation.boundingBox)
    let sharpness = calculateSharpness(buffer, region: observation.boundingBox)

    var failureReasons: [String] = []

    if captureQuality < configuration.minQualityScore {
      failureReasons.append("Low capture quality")
    }

    if brightness < configuration.minBrightness {
      failureReasons.append("Too bright")
    }

    return FaceQualityResult(
      overallQuality: captureQuality,
      captureQuality: captureQuality,
      sharpness: sharpness,
      brightness: brightness,
      contrast: nil,
      isEyesOpen: nil,
      hasGlasses: nil,
      hasObstructions: nil,
      meetsRequirements: failureReasons.isEmpty,
      failureReasons: failureReasons
    )
  }

  private func calculateBrightness(
    _: CVPixelBuffer,
    region _: CGRect
  ) -> Float {
    // Implementation: Calculate average luminance in face region
    0.5 // Placeholder
  }

  private func calculateSharpness(
    _: CVPixelBuffer,
    region _: CGRect
  ) -> Float {
    // Impelementation: Calculate Laplacian variance for blur detection
    0.5 // Placeholder
  }
}
