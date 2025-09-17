import AVFoundation
import CoreMedia
import UIKit

public enum CameraDevicePosition {
	case front
	case back
	
	var avPosition: AVCaptureDevice.Position {
		switch self {
		case .front: return .front
		case .back: return .back
		}
	}
	
	var preferredDeviceTypes: [AVCaptureDevice.DeviceType] {
		switch self {
		case .front:
			return [
				.builtInTrueDepthCamera,
				.builtInWideAngleCamera
			]
		case .back:
			return [
				.builtInTripleCamera,
					.builtInDualCamera,
					.builtInDualWideCamera,
					.builtInWideAngleCamera
			]
		}
	}
}
