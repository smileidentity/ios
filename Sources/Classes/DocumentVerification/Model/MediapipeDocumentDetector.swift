import CoreGraphics
import CoreMedia
import CoreVideo
import Foundation

#if canImport(MediaPipeTasksVision)
import MediaPipeTasksVision
import UIKit

enum MediapipeDocumentDetector {
  private struct PendingDetection {
    let imageSize: CGSize
    let completion: (DocumentDetection?) -> Void
  }

  private static let minimumConfidence: Float = 0.6
  private static let labelDisplayNames: [String: String] = [
    "FACE": "Face",
    "OTHER_DOCUMENT": "Other Document",
    "ZM_REGISTRATION_CERTIFICATE_BACK": "ZM Registration Certificate Back",
    "ZM_REGISTRATION_CERTIFICATE_FRONT": "ZM Registration Certificate Front"
  ]
  private static let timestampLock = NSLock()
  private static var lastTimestamp: Int = 0
  private static let pendingLock = NSLock()
  private static var pendingDetections: [Int: PendingDetection] = [:]
  private static let streamDelegate = LiveStreamDelegate()

  private static let detector: ObjectDetector? = {
    guard let modelURL = SmileIDResourcesHelper.bundle.url(
      forResource: "edetlite0_int8_320_v2_2025_08_29",
      withExtension: "tflite")
    else {
      log("Failed to locate edetlite model in bundle.")
      return nil
    }

    let baseOptions = BaseOptions()
    baseOptions.modelAssetPath = modelURL.path
    baseOptions.delegate = .CPU

    let options = ObjectDetectorOptions()
    options.baseOptions = baseOptions
    options.objectDetectorLiveStreamDelegate = streamDelegate
    options.runningMode = .liveStream
    options.maxResults = 1
    options.scoreThreshold = minimumConfidence

    do {
      log("Initialized detector with model at \(modelURL.lastPathComponent)")
      return try ObjectDetector(options: options)
    } catch {
      log("Unable to initialize detector - \(error.localizedDescription)")
      return nil
    }
  }()

  static func detect(
    pixelBuffer: CVPixelBuffer,
    sampleBuffer: CMSampleBuffer?,
    orientation: UIImage.Orientation?,
    timestampMilliseconds: Int?,
    imageSize: CGSize,
    completion: @escaping (DocumentDetection?) -> Void
  ) {
    guard let detector else {
      log("Detector unavailable; ensure initialization succeeded.")
      completion(nil)
      return
    }

    let mpImage: MPImage
    if let sampleBuffer {
      guard let image = try? MPImage(
        sampleBuffer: sampleBuffer,
        orientation: orientation ?? .up)
      else {
        log("Unable to create MPImage from sample buffer.")
        completion(nil)
        return
      }
      mpImage = image
    } else if let orientation {
      guard let image = try? MPImage(
        pixelBuffer: pixelBuffer,
        orientation: orientation)
      else {
        log("Unable to create MPImage from pixel buffer with orientation \(orientation).")
        completion(nil)
        return
      }
      mpImage = image
    } else if let image = try? MPImage(pixelBuffer: pixelBuffer) {
      mpImage = image
    } else {
      log("Unable to create MPImage from pixel buffer.")
      completion(nil)
      return
    }

    let timestamp = timestampMilliseconds ?? nextTimestamp()
    storePending(
      PendingDetection(imageSize: imageSize, completion: completion),
      timestamp: timestamp)

    do {
      try detector.detectAsync(
        image: mpImage,
        timestampInMilliseconds: timestamp)
      log("Queued frame for detection at timestamp \(timestamp).")
    } catch {
      log("detectAsync reported error at timestamp \(timestamp): \(error.localizedDescription)")
      if let pending = takePending(for: timestamp) {
        pending.completion(nil)
      }
    }
  }

  private static func denormalizedBoundingBox(_ rect: CGRect, imageSize: CGSize) -> CGRect {
    // If the detector returns normalized coordinates (0...1), scale them.
    if rect.maxX <= 1.0, rect.maxY <= 1.0 {
      return CGRect(
        x: rect.origin.x * imageSize.width,
        y: rect.origin.y * imageSize.height,
        width: rect.width * imageSize.width,
        height: rect.height * imageSize.height)
    }
    return rect
  }

  private static func displayName(from rawLabel: String?) -> String? {
    guard let rawLabel else { return nil }
    if let mapped = labelDisplayNames[rawLabel] {
      return mapped
    }
    return rawLabel
      .replacingOccurrences(of: "_", with: " ")
      .capitalized
  }

  private static func buildDocumentDetection(
    from detection: Detection,
    imageSize: CGSize
  ) -> DocumentDetection? {
    let category = detection.categories.first
    let score = category?.score
    let rawLabel = category?.categoryName ?? "(nil)"

    if let score,
       score < minimumConfidence {
      log("Detection filtered out due to low confidence \(score) (< \(minimumConfidence)) for label \(rawLabel).")
      return nil
    }

    let boundingBox = denormalizedBoundingBox(
      detection.boundingBox.standardized,
      imageSize: imageSize)

    guard boundingBox.width > 0, boundingBox.height > 0 else {
      log("Discarding detection with invalid bounding box \(boundingBox).")
      return nil
    }

    let clampedRect = CGRect(
      x: max(0, boundingBox.minX),
      y: max(0, boundingBox.minY),
      width: min(boundingBox.width, imageSize.width - boundingBox.minX),
      height: min(boundingBox.height, imageSize.height - boundingBox.minY))

    guard clampedRect.width > 0, clampedRect.height > 0 else {
      log("Discarding detection with clamped rectangle \(clampedRect).")
      return nil
    }

    let quadrilateral = Quadrilateral(
      topLeft: CGPoint(x: clampedRect.minX, y: clampedRect.minY),
      topRight: CGPoint(x: clampedRect.maxX, y: clampedRect.minY),
      bottomRight: CGPoint(x: clampedRect.maxX, y: clampedRect.maxY),
      bottomLeft: CGPoint(x: clampedRect.minX, y: clampedRect.maxY))

    let classification = displayName(
      from: category?.displayName ?? category?.categoryName)

    if let classification {
      log("Detection success. Label='\(classification)' rawLabel='\(rawLabel)' score=\(score ?? -1) box=\(clampedRect).")
    } else {
      log("Detection success without label. Raw label='\(rawLabel)' score=\(score ?? -1) box=\(clampedRect).")
    }

    return DocumentDetection(
      source: .mediapipe,
      quadrilateral: quadrilateral,
      classification: classification,
      confidence: score)
  }

  private static func storePending(_ pending: PendingDetection, timestamp: Int) {
    pendingLock.lock()
    pendingDetections[timestamp] = pending
    if pendingDetections.count > 5,
       let oldestKey = pendingDetections.keys.sorted().first,
       oldestKey != timestamp,
       let dropped = pendingDetections.removeValue(forKey: oldestKey) {
      pendingLock.unlock()
      log("Pending detection queue full. Dropping frame with timestamp \(oldestKey).")
      dropped.completion(nil)
      return
    }
    pendingLock.unlock()
  }

  private static func takePending(for timestamp: Int) -> PendingDetection? {
    pendingLock.lock()
    let pending = pendingDetections.removeValue(forKey: timestamp)
    pendingLock.unlock()
    if pending == nil {
      log("No pending detection found for timestamp \(timestamp).")
    }
    return pending
  }

  private static func log(_ message: String) {
    guard SmileID.documentDetectionLoggingEnabled else { return }
    print("[SmileID][MediapipeDocumentDetector] \(message)")
  }

  private static func nextTimestamp() -> Int {
    let now = Int(ProcessInfo.processInfo.systemUptime * 1_000)
    timestampLock.lock()
    defer { timestampLock.unlock() }
    if now <= lastTimestamp {
      lastTimestamp += 1
    } else {
      lastTimestamp = now
    }
    return lastTimestamp
  }

  private static func handleResult(
    result: ObjectDetectorResult?,
    timestamp: Int,
    error: Error?
  ) {
    guard let pending = takePending(for: timestamp) else { return }

    if let error {
      log("Detector returned error at timestamp \(timestamp): \(error.localizedDescription)")
      pending.completion(nil)
      return
    }

    guard let detection = result?.detections.first else {
      log("No detections returned for timestamp \(timestamp).")
      pending.completion(nil)
      return
    }

    guard let documentDetection = buildDocumentDetection(from: detection, imageSize: pending.imageSize) else {
      pending.completion(nil)
      return
    }

    pending.completion(documentDetection)
  }

  static func reset() {
    pendingLock.lock()
    pendingDetections.removeAll()
    pendingLock.unlock()
    timestampLock.lock()
    lastTimestamp = 0
    timestampLock.unlock()
    log("Reset MediapipeDocumentDetector state.")
  }

  private final class LiveStreamDelegate: NSObject, ObjectDetectorLiveStreamDelegate {
    func objectDetector(
      _ objectDetector: ObjectDetector,
      didFinishDetection detectionResult: ObjectDetectorResult?,
      timestampInMilliseconds timestamp: Int,
      error: Error?
    ) {
      MediapipeDocumentDetector.handleResult(
        result: detectionResult,
        timestamp: timestamp,
        error: error)
    }
  }
}
#else
enum MediapipeDocumentDetector {
  static func detect(
    pixelBuffer: CVPixelBuffer,
    sampleBuffer: CMSampleBuffer?,
    orientation: UIImage.Orientation?,
    timestampMilliseconds: Int?,
    imageSize: CGSize,
    completion: @escaping (DocumentDetection?) -> Void
  ) {
    completion(nil)
  }

  static func reset() {}
}
#endif
