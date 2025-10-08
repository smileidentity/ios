import CoreGraphics
import CoreImage
import CoreMedia
import CoreVideo
import Foundation
import UIKit
import Vision

struct DocumentDetection {
  enum Source {
    case mediapipe
    case vision
  }

  let source: Source
  let quadrilateral: Quadrilateral
  let classification: String?
  let confidence: Float?
}

enum DocumentDetector {
  static func detectQuadrilateral(
    in pixelBuffer: CVPixelBuffer,
    sampleBuffer: CMSampleBuffer?,
    orientation: UIImage.Orientation?,
    timestampMilliseconds: Int?,
    imageSize: CGSize,
    aspectRatio _: Double?,
    completion: @escaping (DocumentDetection?) -> Void
  ) {
    let performVisionDetection = {
      if #available(iOS 15.0, *) {
        DocumentSegmentation.perform(
          on: pixelBuffer,
          imageSize: imageSize,
          completion: completion)
      } else {
        RectangleDetector.rectangle(
          forPixelBuffer: pixelBuffer,
          aspectRatio: nil
        ) { quadrilateral in
          guard let quadrilateral else {
            completion(nil)
            return
          }
          completion(DocumentDetection(
            source: .vision,
            quadrilateral: quadrilateral,
            classification: nil,
            confidence: nil))
        }
      }
    }

    switch SmileID.documentDetectionBackend {
    case .mediapipeOnly:
      MediapipeDocumentDetector.detect(
        pixelBuffer: pixelBuffer,
        sampleBuffer: sampleBuffer,
        orientation: orientation,
        timestampMilliseconds: timestampMilliseconds,
        imageSize: imageSize,
        completion: completion)

    case .visionOnly:
      performVisionDetection()

    case .automatic:
      MediapipeDocumentDetector.detect(
        pixelBuffer: pixelBuffer,
        sampleBuffer: sampleBuffer,
        orientation: orientation,
        timestampMilliseconds: timestampMilliseconds,
        imageSize: imageSize
      ) { detection in
        if let detection {
          completion(detection)
        } else {
          log("Mediapipe detection unavailable; falling back to Vision.")
          performVisionDetection()
        }
      }
    }
  }

  /// Applies `CIPerspectiveCorrection` to the given pixel buffer using the provided quadrilateral.
  /// - Parameters:
  ///   - pixelBuffer: Source buffer containing the raw capture frame.
  ///   - quadrilateral: Detected document bounds in the buffer’s coordinate space.
  /// - Returns: A perspective-corrected `CIImage` focused on the detected document, if one can be produced.
  static func perspectiveCorrectedImage(
    from pixelBuffer: CVPixelBuffer,
    quadrilateral: Quadrilateral
  ) -> CIImage? {
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    let boundingBox = quadrilateral.cgRect

    guard boundingBox.width > 0,
          boundingBox.height > 0,
          ciImage.extent.contains(boundingBox) else {
      return nil
    }

    let translation = CGAffineTransform(translationX: -boundingBox.origin.x, y: -boundingBox.origin.y)
    let normalizedQuad = quadrilateral.applying(translation)

    guard let filter = CIFilter(name: "CIPerspectiveCorrection") else {
      return nil
    }

    let cropped = ciImage.cropped(to: boundingBox)
      .transformed(by: translation)

    filter.setValue(cropped, forKey: kCIInputImageKey)
    filter.setValue(CIVector(cgPoint: normalizedQuad.topLeft), forKey: "inputTopLeft")
    filter.setValue(CIVector(cgPoint: normalizedQuad.topRight), forKey: "inputTopRight")
    filter.setValue(CIVector(cgPoint: normalizedQuad.bottomLeft), forKey: "inputBottomLeft")
    filter.setValue(CIVector(cgPoint: normalizedQuad.bottomRight), forKey: "inputBottomRight")

    return filter.outputImage
  }

  @available(iOS 15.0, *)
  private enum DocumentSegmentation {
    /// Minimum Vision confidence we consider for segmentation hits.
    private static let minimumConfidence: VNConfidence = 0.9
    /// Reject tiny boxes that likely are not the document (normalized against the frame bounds).
    private static let minimumNormalizedDocumentArea: CGFloat = 0.08

    static func perform(
      on pixelBuffer: CVPixelBuffer,
      imageSize: CGSize,
      completion: @escaping (DocumentDetection?) -> Void
    ) {
      let request = VNDetectDocumentSegmentationRequest { request, error in
        if let error {
          print("VNDetectDocumentSegmentationRequest failed: \(error.localizedDescription)")
          completion(nil)
          return
        }

        guard let observations = request.results as? [VNRectangleObservation],
              let bestObservation = observations
              .filter({
                $0.confidence >= minimumConfidence &&
                  $0.boundingBox.width * $0.boundingBox.height >= minimumNormalizedDocumentArea
              })
              .max(by: { $0.confidence < $1.confidence }) else {
          completion(nil)
          return
        }

        let quadrilateral = Quadrilateral(rectangleObservation: bestObservation)
        let transform = CGAffineTransform.identity
          .scaledBy(x: imageSize.width, y: imageSize.height)
        completion(DocumentDetection(
          source: .vision,
          quadrilateral: quadrilateral.applying(transform),
          classification: nil,
          confidence: nil))
      }

      let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
      do {
        try handler.perform([request])
      } catch {
        print("VNImageRequestHandler error: \(error.localizedDescription)")
        completion(nil)
      }
    }
  }

  private static func log(_ message: String) {
    guard SmileID.documentDetectionLoggingEnabled else { return }
    print("[SmileID][DocumentDetector] \(message)")
  }
}
