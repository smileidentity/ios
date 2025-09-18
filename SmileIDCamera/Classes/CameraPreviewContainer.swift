import AVFoundation
import Combine
import SwiftUI

public struct CameraPreviewContainer: UIViewRepresentable {
	private let session: CameraSessionProtocol
	
	public init(session: CameraSessionProtocol) {
		self.session = session
	}
	
	public func makeUIView(context: Context) -> CameraPreviewView {
		let view = CameraPreviewView()
		view.session = session
		return view
	}
	
	public func updateUIView(_ uiView: CameraPreviewView, context: Context) {}
}
