import UIKit
import SwiftUI
import Combine
import SmileIdentity

class HomeViewController: UIViewController, SmartSelfieResultDelegate {
    var cameraVC: UIViewController?
    var cancellable: AnyCancellable?

    @IBOutlet var versionLabel: CopyableLabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        let partnerID = try? Config(url: Constant.configUrl).partnerId
        versionLabel.text = "Partner \(partnerID ?? "")"
    }

    @IBAction func onSmartSelfieRegistrationTap(_ sender: Any) {
        let smartSelfieAuthenticationView = SmileIdentity.smartSelfieRegistrationScreen(delegate: self)
        cameraVC = UIHostingController(rootView: smartSelfieAuthenticationView)
        cameraVC?.modalPresentationStyle = .fullScreen
        navigationController?.present(cameraVC!, animated: true)
    }

    @IBAction func onSmartSelfieAuthenticationTap(_ sender: Any) {
        if let userIDController = storyboard?.instantiateViewController(withIdentifier: "UserIDViewController")
            as? UserIDViewController {
            navigationController?.pushViewController(userIDController, animated: true)
        }
    }

    func didSucceed(selfieImage: Data, livenessImages: [Data], jobStatusResponse: JobStatusResponse) {
        cameraVC?.dismiss(animated: true, completion: {
            let ac =
            UIAlertController(title: "Selfie Capture Complete",
                              message: "The Job has been submited. Check your Portal for the status of the job",
                              preferredStyle: .alert)
            ac.addAction(.init(title: "Okay", style: .default))
            self.navigationController?.present(ac, animated: true)
        })
    }

    func didError(error: Error) {
        print("Error - \(error.localizedDescription)")
    }
}
