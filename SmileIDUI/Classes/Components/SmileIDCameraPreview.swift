import SwiftUI

struct SmileIDCameraPreview: View {
	var body: some View {
		Rectangle()
			.fill(Color.black)
			.overlay(
				Text("Camera Preview")
					.foregroundColor(.white)
					.font(.title)
			)
	}
}
