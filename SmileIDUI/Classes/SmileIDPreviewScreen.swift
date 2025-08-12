import SwiftUI

public struct SmileIDPreviewScreen<ContinueButton: View, RetryButton: View>: View {
  var onContinue: () -> Void
  var onRetry: () -> Void

  @ViewBuilder var continueButton: ContinueButton
  @ViewBuilder var retryButton: RetryButton

	public init(
    onContinue: @escaping () -> Void,
    onRetry: @escaping () -> Void,
    @ViewBuilder continueButton: () -> ContinueButton,
    @ViewBuilder retryButton: () -> RetryButton
  ) {
    self.onContinue = onContinue
    self.onRetry = onRetry
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

extension SmileIDPreviewScreen where ContinueButton == SmileIDButton, RetryButton == SmileIDButton {
  public init(
    onContinue: @escaping () -> Void,
    onRetry: @escaping () -> Void
  ) {
    self.init(
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
