import SwiftUI

struct SmileIDButtonStyle: ButtonStyle {
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.frame(maxWidth: .infinity)
			.padding()
			.background(Color.blue)
			.foregroundColor(.white)
			.clipShape(Capsule())
			.scaleEffect(configuration.isPressed ? 0.9 : 1)
			.animation(.easeOut(duration: 0.2), value: configuration.isPressed)
	}
}
