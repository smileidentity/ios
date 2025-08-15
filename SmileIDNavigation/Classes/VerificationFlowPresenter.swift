import SwiftUI
import UIKit

public enum VerificationFlowPresenter {
  // Create a UIViewController that hosts the SwiftUI flow.
  static func makeViewController(
    product: BusinessProduct,
    onEvent: VerificationEventSink? = nil,
    onCompletion: @escaping VerificationCompletion
  ) -> UIViewController {
    let root = VerificationFlowView(
      product: product,
      onEvent: onEvent,
      onCompletion: onCompletion
    )
    return UIHostingController(rootView: root)
  }

  // Present modally from UIKit and await a completion via callback
  static func present(
    from presenter: UIViewController,
    product: BusinessProduct,
    onEvent: VerificationEventSink? = nil,
    onCompletion: @escaping VerificationCompletion
  ) {
    let viewController = makeViewController(
      product: product,
      onEvent: onEvent,
      onCompletion: onCompletion
    )
    viewController.modalPresentationStyle = .fullScreen
    presenter.present(viewController, animated: true)
  }
}
