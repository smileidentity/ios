import SwiftUI

public struct SmileIDProcessingScreen<ContinueButton: View, CancelButton: View>: View {
  var onContinue: () -> Void
  var onCancel: () -> Void
  
	@Backport.StateObject private var viewModel: ProcessingScreenViewModel
  @ViewBuilder var continueButton: ContinueButton
  @ViewBuilder var cancelButton: CancelButton

  public init(
    onContinue: @escaping () -> Void,
    onCancel: @escaping () -> Void,
    @ViewBuilder continueButton: () -> ContinueButton,
    @ViewBuilder cancelButton: () -> CancelButton
  ) {
    self.onContinue = onContinue
    self.onCancel = onCancel
		self._viewModel = Backport.StateObject(
			wrappedValue: ProcessingScreenViewModel(
				onContinue: onContinue,
				onCancel: onCancel
			)
		)
    self.continueButton = continueButton()
    self.cancelButton = cancelButton()
  }

  public var body: some View {
    VStack {
      ScrollView(.vertical) {
        Text("Processing")
          .font(.title)
        Text("Please wait while we process your information")
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

public extension SmileIDProcessingScreen where ContinueButton == SmileIDButton, CancelButton == SmileIDButton {
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
      SmileIDProcessingScreen(
        onContinue: {},
        onCancel: {}
      )
    }
  }
#endif
