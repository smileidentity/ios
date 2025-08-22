import Foundation
import Vision

/// Lightweight wrapper around Vision's VNTrackObjectRequest to track a single face
/// across frames and surface a synthetic VNFaceObservation when tracking succeeds.
final class VisionFaceTracker {
  enum UpdateResult {
    case tracked(VNFaceObservation)
    case lost(exceededThreshold: Bool)
    case noTracker
  }

  private let queue = DispatchQueue(label: "com.smileid.selfieFaceTracker")
  private var sequenceRequestHandler = VNSequenceRequestHandler()
  private var trackingRequest: VNTrackObjectRequest?
  private var lostFrameCount = 0

  private let confidenceThreshold: Float
  private let maxLostFrames: Int

  init(
    confidenceThreshold: Float = 0.40,
    maxLostFrames: Int = 10
  ) {
    self.confidenceThreshold = confidenceThreshold
    self.maxLostFrames = maxLostFrames
  }

  var isTracking: Bool { trackingRequest != nil }

  /// Attempt to update the existing tracker with a new frame.
  /// - Returns: `.tracked(face)` when tracking succeeds, `.lost` when it fails,
  ///            or `.noTracker` when no active tracker exists.
  func update(with pixelBuffer: CVPixelBuffer) -> UpdateResult {
    guard let trackingRequest else { return .noTracker }

    var result: UpdateResult = .noTracker
    queue.sync {
      do {
        try sequenceRequestHandler.perform([trackingRequest], on: pixelBuffer)

        if let observation = trackingRequest.results?.first as? VNDetectedObjectObservation,
           observation.confidence > confidenceThreshold,
           !trackingRequest.isLastFrame {
          // successful update – feed synthetic VNFaceObservation downstream
          lostFrameCount = 0
          trackingRequest.inputObservation = observation // keep tracker smooth next frame
          let synthetic = VNFaceObservation(boundingBox: observation.boundingBox)
          result = .tracked(synthetic)
        } else {
          // Tracker lost – increment counter
          lostFrameCount += 1
          result = .lost(exceededThreshold: lostFrameCount >= maxLostFrames)
        }
      } catch {
        debug("Sequence tracking error: \(error.localizedDescription)", category: "VisionFaceTracker")
        // treat errors as lost frames but do not exceed threshold immediately
        lostFrameCount += 1
        result = .lost(exceededThreshold: lostFrameCount >= maxLostFrames)
      }
    }

    return result
  }

  /// Start tracking using a detected face's bounding box.
  func startTracking(from face: VNFaceObservation) {
    let initial = VNDetectedObjectObservation(boundingBox: face.boundingBox)
    let request = VNTrackObjectRequest(detectedObjectObservation: initial)
    request.trackingLevel = .accurate
    trackingRequest = request
    lostFrameCount = 0
  }

  /// Cancel the current tracker and reset counters.
  func cancelTracking() {
    trackingRequest = nil
    lostFrameCount = 0
  }
}
