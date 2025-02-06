import SmileID
import SwiftUI
import UIKit

@objcMembers
class SelfieCaptureViewModel: NSObject, @preconcurrency SmartSelfieResultDelegate {
    func didSucceed(selfieImage: URL, livenessImages: [URL], apiResponse: SmartSelfieResponse?) {
        print(selfieImage)
        print(livenessImages.map { $0 })
        print(apiResponse?.code ?? "")
    }

    @MainActor func didError(error: any Error) {
        print(error.localizedDescription)
        UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true)
    }
}

@objcMembers
class SelfieCaptureViewController: UIViewController {
    let viewModel: SelfieCaptureViewModel = SelfieCaptureViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        embedSwiftUIView()
    }

    private func embedSwiftUIView() {
        let smartSelfieView = SmileID.smartSelfieEnrollmentScreen(delegate: viewModel)
        let viewController = UIHostingController(rootView: smartSelfieView)
        let swiftUIView = viewController.view!

        swiftUIView.translatesAutoresizingMaskIntoConstraints = false
        swiftUIView.backgroundColor = .white

        addChild(viewController)
        view.addSubview(swiftUIView)

        NSLayoutConstraint.activate([
            swiftUIView.topAnchor.constraint(equalTo: view.topAnchor),
            swiftUIView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            swiftUIView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            swiftUIView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        viewController.didMove(toParent: self)
    }
}
