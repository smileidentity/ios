import SwiftUI
import UIKit

// MARK: - Configuration

public struct SmileIDScreenConfiguration {
	public var continueButtonTitle: String
	public var cancelButtonTitle: String
	public var retryButtonTitle: String

	public init(
		continueButtonTitle: String = "Continue",
		cancelButtonTitle: String = "Cancel",
		retryButtonTitle: String = "Retry"
	) {
		self.continueButtonTitle = continueButtonTitle
		self.cancelButtonTitle = cancelButtonTitle
		self.retryButtonTitle = retryButtonTitle
	}

	public static let `default` = SmileIDScreenConfiguration()
}

// MARK: - UIViewController Factory Extensions

extension SmileIDCaptureScreen where ContinueButton == SmileIDButton {
	public static func viewController(
		scanType: ScanType,
		onContinue: @escaping () -> Void,
		configuration: SmileIDScreenConfiguration = .default
	) -> UIViewController {
		let screen = SmileIDCaptureScreen(
			scanType: scanType,
			onContinue: onContinue,
			continueButton: {
				SmileIDButton(
					text: configuration.continueButtonTitle,
					onClick: onContinue
				)
			}
		)
		return UIHostingController(rootView: screen)
	}
}

extension SmileIDInstructionsScreen where ContinueButton == SmileIDButton, CancelButton == SmileIDButton {
	public static func viewController(
		onContinue: @escaping () -> Void,
		onCancel: @escaping () -> Void,
		configuration: SmileIDScreenConfiguration = .default
	) -> UIViewController {
		let screen = SmileIDInstructionsScreen(
			onContinue: onContinue,
			onCancel: onCancel,
			continueButton: {
				SmileIDButton(
					text: configuration.continueButtonTitle,
					onClick: onContinue
				)
			},
			cancelButton: {
				SmileIDButton(
					text: configuration.cancelButtonTitle,
					onClick: onCancel
				)
			}
		)
		return UIHostingController(rootView: screen)
	}
}

extension SmileIDPreviewScreen where ContinueButton == SmileIDButton, RetryButton == SmileIDButton {
	public static func viewController(
		onContinue: @escaping () -> Void,
		onRetry: @escaping () -> Void,
		configuration: SmileIDScreenConfiguration = .default
	) -> UIViewController {
		let screen = SmileIDPreviewScreen(
			onContinue: onContinue,
			onRetry: onRetry,
			continueButton: {
				SmileIDButton(
					text: configuration.continueButtonTitle,
					onClick: onContinue
				)
			},
			retryButton: {
				SmileIDButton(
					text: configuration.retryButtonTitle,
					onClick: onRetry
				)
			}
		)
		return UIHostingController(rootView: screen)
	}
}

extension SmileIDProcessingScreen where ContinueButton == SmileIDButton, CancelButton == SmileIDButton {
	public static func viewController(
		onContinue: @escaping () -> Void,
		onCancel: @escaping () -> Void,
		configuration: SmileIDScreenConfiguration = .default
	) -> UIViewController {
		let screen = SmileIDProcessingScreen(
			onContinue: onContinue,
			onCancel: onCancel,
			continueButton: {
				SmileIDButton(
					text: configuration.continueButtonTitle,
					onClick: onContinue
				)
			},
			cancelButton: {
				SmileIDButton(
					text: configuration.cancelButtonTitle,
					onClick: onCancel
				)
			}
		)
		return UIHostingController(rootView: screen)
	}
}
