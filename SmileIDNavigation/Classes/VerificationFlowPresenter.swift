import SwiftUI
import UIKit

public enum VerificationFlowPresenter {
  // Create a UIViewController that hosts the SwiftUI flow.
  static func makeViewController(
    config: VerificationConfig,
    onEvent: VerificationEventSink? = nil,
    onCompletion: @escaping VerificationCompletion
  ) -> UIViewController {
    let root = VerificationFlowView(
      config: config,
      onEvent: onEvent,
      onCompletion: onCompletion
    )
    return UIHostingController(rootView: root)
  }

  // Present modally from UIKit and await a completion via callback
  static func present(
    from presenter: UIViewController,
    config: VerificationConfig,
    onEvent: VerificationEventSink? = nil,
    onCompletion: @escaping VerificationCompletion
  ) {
    let viewController = makeViewController(
      config: config,
      onEvent: onEvent,
      onCompletion: onCompletion
    )
    viewController.modalPresentationStyle = .fullScreen
    presenter.present(viewController, animated: true)
  }
}
