import UIKit
import SwiftUI
import SmileIdentity

class ViewController: UIViewController, SmartSelfieResult {
    var cameraVC: UIViewController?

    @IBAction func onSmartSelfieTap(_ sender: Any) {
        cameraVC = UIHostingController(rootView: SelfieCaptureView(delegate: self))
        navigationController?.present(cameraVC!, animated: true)
    }

    func didSucceed(selfieImage: Data, livenessImages: [Data]) {
        cameraVC?.dismiss(animated: true, completion: {
            let ac =
            UIAlertController(title: "Selfie Capture Complete",
                              message: "Check your camera roll for the captured images",
                              preferredStyle: .alert)
            ac.addAction(.init(title: "Okay", style: .default))
            self.navigationController?.present(ac, animated: true)
        })
    }

    func didError(error: Error) {

    }
}
