import SwiftUI

struct SmileIDInstructionsScreen<ContinueButtonStyle: ButtonStyle, CancelButtonStyle: ButtonStyle>: View {

	var onContinue: () -> Void
	var onCancel: () -> Void
	var continueButtonStyle: ContinueButtonStyle
	var cancelButtonStyle: CancelButtonStyle

	init(
		onContinue: @escaping () -> Void,
		onCancel: @escaping () -> Void,
		continueButtonStyle: ContinueButtonStyle = SmileIDButtonStyle(),
		cancelButtonStyle: CancelButtonStyle = SmileIDButtonStyle()
	) {
		self.onContinue = onContinue
		self.onCancel = onCancel
		self.continueButtonStyle = continueButtonStyle
		self.cancelButtonStyle = cancelButtonStyle
	}

	var body: some View {
		VStack {
			ScrollView(.vertical) {

				Text("Some header here")
					.font(.title)
				Text("Some subtitle here")
				Spacer()
			}

			VStack {
				Button("Continue") {
					onContinue()
				}
				.buttonStyle(continueButtonStyle)

				Button("Cancel") {
					onCancel()
				}
				.buttonStyle(cancelButtonStyle)
			}
			.padding()
		}
	}
}

#if DEBUG
#Preview {
	NavigationView {
		SmileIDInstructionsScreen(
			onContinue: {},
			onCancel: {}
		)
	}
}
#endif
