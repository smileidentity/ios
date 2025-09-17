import Foundation
import AVFoundation

public protocol CameraSessionProtocol: AnyObject {
	var previewView: CameraPreviewView? { get set }
	func configure(
		with configuration: CameraConfiguration,
		delegate: AVCaptureVideoDataOutputSampleBufferDelegate,
		completionQueue: DispatchQueue,
		completion: @escaping (Result<Void, Error>) -> Void
	)
	func setVideoOrientation(_ orientation: AVCaptureVideoOrientation)
	func toggleCamera(
		to position: CameraDevicePosition,
		completionQueue: DispatchQueue,
		completion: @escaping (Result<Void, Error>) -> Void
	)
	func toggleTorch()
	func deviceProperties() -> CameraDeviceProperties?
	func startRunning(
		completionQueue: DispatchQueue,
		completion: @escaping () -> Void
	)
	func stopRunning(
		completionQueue: DispatchQueue,
		completion: @escaping () -> Void
	)
}
