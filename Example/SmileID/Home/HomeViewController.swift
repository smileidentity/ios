import Combine
import SmileID
import SwiftUI
import UIKit

class HomeViewController: UIViewController, SmartSelfieResultDelegate {
    var cameraVC: UIViewController?
    var cancellable: AnyCancellable?
    var userID = ""
    var currentJob = JobType.smartSelfieEnrollment

    @IBOutlet var versionLabel: CopyableLabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        let partnerID = SmileID.configuration.partnerId
        versionLabel.text = "Partner \(partnerID) - Version \(SmileID.version)"
    }

    @IBAction func onEnvironmentToggle(_ sender: UIBarButtonItem) {
        if sender.title!.lowercased() == "sandbox" {
            sender.title = "Production"
        } else {
            sender.title = "Sandbox"
        }
    }

    @IBAction func onSmartSelfieRegistrationTap(_: Any) {
        userID = UUID().uuidString
        currentJob = .smartSelfieEnrollment
        let smartSelfieRegistrationScreen = SmileID.smartSelfieEnrollmentScreen(
            config: OrchestratedSelfieCaptureConfig(
                userId: userID,
                allowAgentMode: true
            ),
            delegate: self
        )
        cameraVC = UIHostingController(rootView: smartSelfieRegistrationScreen)
        cameraVC?.modalPresentationStyle = .fullScreen
        navigationController?.present(cameraVC!, animated: true)
    }

    @IBAction func onSmartSelfieAuthenticationTap(_: Any) {
        currentJob = .smartSelfieAuthentication
    }

    func smartSelfieAuthenticationScreen(userID: String) {
        let smartSelfieAuthenticationScreen = SmileID.smartSelfieAuthenticationScreen(
            config: OrchestratedSelfieCaptureConfig(
                userId: userID,
                allowAgentMode: true
            ),
            delegate: self
        )
        cameraVC = UIHostingController(rootView: smartSelfieAuthenticationScreen)
        cameraVC?.modalPresentationStyle = .fullScreen
        navigationController?.present(cameraVC!, animated: true)
    }

    func didSucceed(
        selfieImage _: URL,
        livenessImages _: [URL],
        apiResponse _: SmartSelfieResponse?
    ) {
        cameraVC?.dismiss(animated: true, completion: {
            switch self.currentJob {
            case .smartSelfieEnrollment:
                UIPasteboard.general.string = self.userID
                let message =
                    "The user has been registered and the user ID has been copied to the clipboard"
                self.presentAlert(
                    title: "SmartSelfie Enrollment Complete",
                    message: message
                )
            case .smartSelfieAuthentication:
                self.presentAlert(
                    title: "SmartSelfie Authentication Complete",
                    message: "The user has been authenticated successfully"
                )
                self.navigationController?.popViewController(animated: true)
            default:
                break
            }
        })
    }

    func presentAlert(title: String, message: String) {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alertController.addAction(.init(title: "Okay", style: .default))
        navigationController?.present(alertController, animated: true)
    }

    func didError(error: Error) {
        presentAlert(title: "An error occurred", message: error.localizedDescription)
    }

    func didCancel() {}
}
