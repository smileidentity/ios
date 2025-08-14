import SmileIDUI
import SwiftUI
import UIKit

@objcMembers
class SmileIDUIKitTestViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .systemBackground
		title = "SmileID UIKit Test"

		setupTestButtons()
	}

	private func setupTestButtons() {
		let stackView = UIStackView()
		stackView.axis = .vertical
		stackView.spacing = 16
		stackView.translatesAutoresizingMaskIntoConstraints = false

		let instructionsButton = createTestButton(title: "Instructions Screen") {
			self.testInstructionsScreen()
		}

		let captureButton = createTestButton(title: "Capture Screen") {
			self.testCaptureScreen()
		}

		let previewButton = createTestButton(title: "Preview Screen") {
			self.testPreviewScreen()
		}

		let processingButton = createTestButton(title: "Processing Screen") {
			self.testProcessingScreen()
		}

		stackView.addArrangedSubview(instructionsButton)
		stackView.addArrangedSubview(captureButton)
		stackView.addArrangedSubview(previewButton)
		stackView.addArrangedSubview(processingButton)

		view.addSubview(stackView)

		NSLayoutConstraint.activate([
			stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
			stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
			stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
		])
	}

	private func createTestButton(
		title: String,
		action: @escaping () -> Void
	) -> UIButton {
		let button = UIButton(type: .system)
		button.setTitle(title, for: .normal)
		button.backgroundColor = .systemBlue
		button.setTitleColor(.white, for: .normal)
		button.layer.cornerRadius = 8
		button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.heightAnchor.constraint(equalToConstant: 50).isActive = true

		button.addAction(UIAction { _ in action() }, for: .touchUpInside)

		return button
	}

	private func testInstructionsScreen() {
		let viewController = SmileIDInstructionsScreen.viewController(
			onContinue: {
				print("Instructions: Continue tapped")
				self.dismiss(animated: true)
			},
			onCancel: {
				print("Instructions: Cancel tapped")
				self.dismiss(animated: true)
			}
		)

		viewController.title = "Instructions"
		let navController = UINavigationController(rootViewController: viewController)
		present(navController, animated: true)
	}

	private func testCaptureScreen() {
		let viewController = SmileIDCaptureScreen.viewController(
			scanType: .documentFront,
			onContinue: {
				print("Capture: Continue tapped")
				self.dismiss(animated: true)
			}
		)

		viewController.title = "Document Capture"
		let navController = UINavigationController(rootViewController: viewController)
		present(navController, animated: true)
	}

	private func testPreviewScreen() {
		let viewController = SmileIDPreviewScreen.viewController(
			onContinue: {
				print("Preview: Continue tapped")
				self.dismiss(animated: true)
			},
			onRetry: {
				print("Preview: Retry tapped")
				self.dismiss(animated: true)
			}
		)

		viewController.title = "Preview"
		let navController = UINavigationController(rootViewController: viewController)
		present(navController, animated: true)
	}

	private func testProcessingScreen() {
		let viewController = SmileIDProcessingScreen.viewController(
			onContinue: {
				print("Processing: Continue tapped")
				self.dismiss(animated: true)
			},
			onCancel: {
				print("Processing: Cancel tapped")
				self.dismiss(animated: true)
			}
		)

		viewController.title = "Processing"
		let navController = UINavigationController(rootViewController: viewController)
		present(navController, animated: true)
	}
}

#if DEBUG
struct SmileIDUIKitTestViewController_Previews: PreviewProvider {
	static var previews: some View {
		UIViewControllerPreview {
			SmileIDUIKitTestViewController()
		}
	}
}

struct UIViewControllerPreview<ViewController: UIViewController>: UIViewControllerRepresentable {
	let viewControllerBuilder: () -> ViewController
	
	init(_ viewControllerBuilder: @escaping () -> ViewController) {
		self.viewControllerBuilder = viewControllerBuilder
	}
	
	func makeUIViewController(context: Context) -> ViewController {
		viewControllerBuilder()
	}
	
	func updateUIViewController(_ uiViewController: ViewController, context: Context) {
		// Nothing to update
	}
}
#endif
