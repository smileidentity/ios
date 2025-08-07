import SwiftUI

struct SmileIDInstructionsScreen<ContinueButton: View, CancelButton: View>: View {
  var onContinue: () -> Void
  var onCancel: () -> Void

	@ViewBuilder var continueButton: ContinueButton
	@ViewBuilder var cancelButton: CancelButton

  init(
    onContinue: @escaping () -> Void,
    onCancel: @escaping () -> Void,
		@ViewBuilder continueButton: () -> ContinueButton,
		@ViewBuilder cancelButton: () -> CancelButton
  ) {
    self.onContinue = onContinue
    self.onCancel = onCancel
    self.continueButton = continueButton()
    self.cancelButton = cancelButton()
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
        continueButton
        cancelButton
      }
      .padding()
    }
  }
}

extension SmileIDInstructionsScreen where ContinueButton == SmileIDButton, CancelButton == SmileIDButton {
  init(
    onContinue: @escaping () -> Void,
    onCancel: @escaping () -> Void
  ) {
    self.init(
      onContinue: onContinue,
      onCancel: onCancel,
			continueButton: {
				SmileIDButton(text: "Continue", onClick: onContinue)
			},
			cancelButton: {
				SmileIDButton(text: "Cancel", onClick: onCancel)
			}
    )
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
