import Foundation
@preconcurrency import Vision

final class VisionDocumentDetector: DocumentDetecting {
  private let configuration: ModelConfiguration
  private let processingQueue = DispatchQueue(
    label: "com.smileid.vision.document",
    qos: .userInitiated
  )

  init(configuration: ModelConfiguration) {
    self.configuration = configuration
  }

  func detectDocument(
    in buffer: CVPixelBuffer
  ) async throws -> DocumentDetectionResult {
    if #available(iOS 15.0, *) {
      return try await detectDocumentWithSegmentation(in: buffer)
    } else {
      return try await detectDocumentWithRectangles(in: buffer)
    }
  }

  @available(iOS 15.0, *)
  private func detectDocumentWithSegmentation(
    in buffer: CVPixelBuffer
  ) async throws -> DocumentDetectionResult {
    try await withCheckedThrowingContinuation { continuation in
      let request = VNDetectDocumentSegmentationRequest { request, error in
        if let error {
          continuation.resume(throwing: ModelError.inferenceError(underlying: error))
          return
        }

        guard let observation = request.results?.first as? VNRectangleObservation else {
          continuation.resume(throwing: ModelError.invalidInput)
          return
        }

        let result = self.convertToDocumentResult(observation)
        continuation.resume(returning: result)
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

  private func detectDocumentWithRectangles(
    in buffer: CVPixelBuffer
  ) async throws -> DocumentDetectionResult {
    try await withCheckedThrowingContinuation { continuation in
      let request = VNDetectRectanglesRequest { request, error in
        if let error {
          continuation.resume(throwing: ModelError.inferenceError(underlying: error))
          return
        }

        guard let observations = request.results as? [VNRectangleObservation],
              let observation = observations.first else {
          continuation.resume(throwing: ModelError.invalidInput)
          return
        }

        let result = self.convertToDocumentResult(observation)
        continuation.resume(returning: result)
      }

      request.minimumAspectRatio = 0.5
      request.maximumAspectRatio = 0.95
      request.minimumSize = 0.3
      request.maximumObservations = 1

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

  private func convertToDocumentResult(
    _ observation: VNRectangleObservation
  ) -> DocumentDetectionResult {
    DocumentDetectionResult(
      boundingBox: observation.boundingBox,
      corners: [
        observation.topLeft,
        observation.topRight,
        observation.bottomRight,
        observation.bottomLeft
      ],
      documentType: nil, // Will be classified at a later stage
      confidence: observation.confidence
    )
  }
}
