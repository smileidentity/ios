import Foundation
import Vision

enum FaceTrackingState {
	case detecting
	case tracking
	case lost
	case reset
}

enum FaceTrackingError: Error {
	case multipleFacesDetected
	case noFaceDetected
	case trackingLost
	case trackingConfidenceTooLow
	case differentFaceDetected
}

protocol FaceTrackingDelegate: AnyObject {
	func faceTrackingStateChanged(_ state: FaceTrackingState)
	func faceTrackingDidFail(with error: FaceTrackingError)
	func faceTrackingDidReset()
}

struct FaceTrackingConfiguration {
	let confidenceThreshold: Float
	let trackingLevel: VNRequestTrackingLevel
	let maxTrackingLossFrames: Int
	let usesCPUOnly: Bool

	static let `default` = FaceTrackingConfiguration(
		confidenceThreshold: 0.3,
		trackingLevel: .fast,
		maxTrackingLossFrames: 30,
		usesCPUOnly: false
	)
}
