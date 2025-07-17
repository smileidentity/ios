import Foundation
import UIKit
import Vision

class FaceTrackingManager: NSObject {
  private var trackingRequest: VNTrackObjectRequest?
  private var trackedFaceUUID: UUID?
  private var sequenceHandler = VNSequenceRequestHandler()
  private var currentState: FaceTrackingState = .detecting
  private var trackingLossFrameCount: Int = 0

  private let configuration: FaceTrackingConfiguration

  weak var delegate: FaceTrackingDelegate?

  init(configuration: FaceTrackingConfiguration = .default) {
    self.configuration = configuration
    super.init()
  }

  var isTracking: Bool {
    currentState == .tracking
  }

  var trackingState: FaceTrackingState {
    currentState
  }

  func startTracking(with faceObservation: VNFaceObservation) {
    guard currentState == .detecting else { return }

    let newTrackingRequest = VNTrackObjectRequest(detectedObjectObservation: faceObservation)
    newTrackingRequest.trackingLevel = configuration.trackingLevel

    trackingRequest = newTrackingRequest
    // The UUID will be captured from the first tracking result
    trackedFaceUUID = nil
    trackingLossFrameCount = 0

    updateState(.tracking)
  }

  func processFrame(_ pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation = .leftMirrored) {
    guard let trackingRequest,
          currentState == .tracking else { return }

    do {
      try sequenceHandler.perform([trackingRequest], on: pixelBuffer, orientation: orientation)

      guard let observations = trackingRequest.results as? [VNDetectedObjectObservation] else {
        handleTrackingLoss()
        return
      }

      processTrackingResults(observations)
    } catch {
      handleTrackingFailure(error)
    }
  }

  private func processTrackingResults(_ observations: [VNDetectedObjectObservation]) {
    // Get the first observation from tracking results
    guard let observation = observations.first else {
      handleTrackingLoss()
      return
    }

    // If this is the first tracking result, capture its UUID
    if trackedFaceUUID == nil {
      trackedFaceUUID = observation.uuid
    }

    // Check if this observation matches our tracked face UUID
    if observation.uuid == trackedFaceUUID {
      if observation.confidence > configuration.confidenceThreshold {
        trackingLossFrameCount = 0
        trackingRequest?.inputObservation = observation
      } else {
        handleTrackingLoss()
      }
    } else {
      // Different face detected - this shouldn't happen with single object tracking
      // but we handle it as a safety measure
      delegate?.faceTrackingDidFail(with: .differentFaceDetected)
      resetTracking()
    }
  }

  private func handleTrackingLoss() {
    trackingLossFrameCount += 1

    if trackingLossFrameCount >= configuration.maxTrackingLossFrames {
      delegate?.faceTrackingDidFail(with: .trackingLost)
      resetTracking()
    }
  }

  private func handleTrackingFailure(_: Error) {
    delegate?.faceTrackingDidFail(with: .trackingLost)
    resetTracking()
  }

  func resetTracking() {
    trackingRequest?.isLastFrame = true
    trackingRequest = nil
    trackedFaceUUID = nil
    trackingLossFrameCount = 0
    sequenceHandler = VNSequenceRequestHandler()

    updateState(.reset)
    delegate?.faceTrackingDidReset()

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      self.updateState(.detecting)
    }
  }

  private func updateState(_ newState: FaceTrackingState) {
    guard currentState != newState else { return }
    currentState = newState
    delegate?.faceTrackingStateChanged(newState)
  }

  deinit {
    resetTracking()
  }
}
