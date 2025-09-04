import SwiftUI
import UIKit

// MARK: - UIViewController Factory Extensions

public extension SmileIDCaptureScreen where ContinueButton == SmileIDButton {
  static func viewController(
    scanType: ScanType,
    onContinue: @escaping () -> Void
  ) -> UIViewController {
    let screen = SmileIDCaptureScreen(
      scanType: scanType,
      onContinue: onContinue,
      continueButton: {
        SmileIDButton(
          text: "Continue",
          onClick: onContinue
        )
      }
    )
    return UIHostingController(rootView: screen)
  }
}

public extension SmileIDInstructionsScreen where ContinueButton == SmileIDButton, CancelButton == SmileIDButton {
  static func viewController(
    onContinue: @escaping () -> Void,
    onCancel: @escaping () -> Void
  ) -> UIViewController {
    let screen = SmileIDInstructionsScreen(
      onContinue: onContinue,
      onCancel: onCancel,
      continueButton: {
        SmileIDButton(
          text: "Take Selfie",
          onClick: onContinue
        )
      },
      cancelButton: {
        SmileIDButton(
          text: "Cancel",
          onClick: onCancel
        )
      }
    )
    return UIHostingController(rootView: screen)
  }
}

public extension SmileIDPreviewScreen where ContinueButton == SmileIDButton, RetryButton == SmileIDButton {
  static func viewController(
    onContinue: @escaping () -> Void,
    onRetry: @escaping () -> Void
  ) -> UIViewController {
    let screen = SmileIDPreviewScreen(
      onContinue: onContinue,
      onRetry: onRetry,
      continueButton: {
        SmileIDButton(
          text: "Continue",
          onClick: onContinue
        )
      },
      retryButton: {
        SmileIDButton(
          text: "Retry",
          onClick: onRetry
        )
      }
    )
    return UIHostingController(rootView: screen)
  }
}

public extension SmileIDProcessingScreen where ContinueButton == SmileIDButton, CancelButton == SmileIDButton {
  static func viewController(
    onContinue: @escaping () -> Void,
    onCancel: @escaping () -> Void
  ) -> UIViewController {
    let screen = SmileIDProcessingScreen(
      onContinue: onContinue,
      onCancel: onCancel,
      continueButton: {
        SmileIDButton(
          text: "Continue",
          onClick: onContinue
        )
      },
      cancelButton: {
        SmileIDButton(
          text: "Cancel",
          onClick: onCancel
        )
      }
    )
    return UIHostingController(rootView: screen)
  }
}
