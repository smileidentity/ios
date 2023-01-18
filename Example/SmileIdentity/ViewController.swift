import UIKit
import SwiftUI
import SmileIdentity

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let cameraVC = UIHostingController(rootView: SelfieCaptureView())
        navigationController?.present(cameraVC, animated: true)
    }
}
