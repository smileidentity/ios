import UIKit
import SwiftUI
import SmileIdentity

class ViewController: UIViewController, SmartSelfieResult {

    override func viewDidLoad() {
        super.viewDidLoad()
        let cameraVC = UIHostingController(rootView: SelfieCaptureView(delegate: self))
        navigationController?.present(cameraVC, animated: true)
    }

    func didSucceed(selfieImage: Data, livenessImages: [Data]) {

    }

    func didError(error: Error) {
        
    }
}
