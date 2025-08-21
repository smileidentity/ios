import SwiftUI

public struct SmileIDPreviewScreen<ContinueButton: View, RetryButton: View>: View {
  var onContinue: () -> Void
  var onRetry: () -> Void
  
	@Backport.StateObject private var viewModel: PreviewScreenViewModel
  @ViewBuilder var continueButton: ContinueButton
  @ViewBuilder var retryButton: RetryButton

  public init(
    capturedImage: Data? = nil,
    scanType: ScanType = .selfie,
    onContinue: @escaping () -> Void,
    onRetry: @escaping () -> Void,
    @ViewBuilder continueButton: () -> ContinueButton,
    @ViewBuilder retryButton: () -> RetryButton
  ) {
    self.onContinue = onContinue
    self.onRetry = onRetry
		self._viewModel = Backport.StateObject(
			wrappedValue: PreviewScreenViewModel(
				capturedImage: capturedImage,
				scanType: scanType,
				onContinue: onContinue,
				onRetry: onRetry
			)
		)
    self.continueButton = continueButton()
    self.retryButton = retryButton()
  }

  public var body: some View {
    VStack {
      ScrollView(.vertical) {
        Text("Preview")
          .font(.title)
        Text("Please review your captured image")
        Spacer()
      }

      VStack {
        continueButton
        retryButton
      }
      .padding()
    }
  }
}

public extension SmileIDPreviewScreen where ContinueButton == SmileIDButton, RetryButton == SmileIDButton {
  init(
    capturedImage: Data? = nil,
    scanType: ScanType = .selfie,
    onContinue: @escaping () -> Void,
    onRetry: @escaping () -> Void
  ) {
    self.init(
      capturedImage: capturedImage,
      scanType: scanType,
      onContinue: onContinue,
      onRetry: onRetry,
      continueButton: {
        SmileIDButton(text: "Continue", onClick: onContinue)
      },
      retryButton: {
        SmileIDButton(text: "Retry", onClick: onRetry)
      }
    )
  }
}

#if DEBUG
  #Preview {
    NavigationView {
      SmileIDPreviewScreen(
        onContinue: {},
        onRetry: {}
      )
    }
  }
#endif
