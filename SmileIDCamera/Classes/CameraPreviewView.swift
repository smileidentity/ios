import UIKit
import AVFoundation

public final class CameraPreviewView: UIView {
	public override class var layerClass: AnyClass {
		AVCaptureVideoPreviewLayer.self
	}
	
	public var videoPreviewLayer: AVCaptureVideoPreviewLayer {
		layer as! AVCaptureVideoPreviewLayer
	}
	
	public weak var session: CameraSessionProtocol? {
		didSet {
			guard oldValue !== session else { return }
			oldValue?.previewView = nil
			session?.previewView = self
		}
	}
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		videoPreviewLayer.videoGravity = .resizeAspectFill
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		videoPreviewLayer.videoGravity = .resizeAspectFill
	}
	
	func setCaptureSession(
		_ captureSession: AVCaptureSession?,
		queue: DispatchQueue
	) {
		let workItem = DispatchWorkItem { [weak self] in
			guard let self else { return }
			queue.async { [weak previewLayer = self.videoPreviewLayer, weak captureSession] in
				previewLayer?.session = captureSession
			}
		}
		
		if Thread.isMainThread {
			workItem.perform()
		} else {
			DispatchQueue.main.async(execute: workItem)
		}
	}
}
