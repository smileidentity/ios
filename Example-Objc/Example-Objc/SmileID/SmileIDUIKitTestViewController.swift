import SmileID
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

    stackView.addArrangedSubview(instructionsButton)

    view.addSubview(stackView)

    NSLayoutConstraint.activate([
      stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
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
    button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.heightAnchor.constraint(equalToConstant: 50).isActive = true

    button.addAction(UIAction { _ in action() }, for: .touchUpInside)

    return button
  }

  private func testInstructionsScreen() {
    OrchestratedSelfieCaptureScreen(
      userId: "",
      jobId: "",
      isEnroll: true,
      allowNewEnroll: true,
      allowAgentMode: true,
      showAttribution: true,
      showInstructions: true,
      smileSensitivity: .relaxed,
      extraPartnerParams: [:],
      skipApiSubmission: true,
      onResult: (any SmartSelfieResultDelegate).self as! SmartSelfieResultDelegate
    )
  }
}
