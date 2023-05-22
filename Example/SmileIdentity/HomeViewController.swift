import UIKit
import SwiftUI
import Combine
import SmileIdentity

class HomeViewController: UIViewController, SmartSelfieResultDelegate {
    var cameraVC: UIViewController?
    var cancellable: AnyCancellable?
    var userID = ""
    var currentJob = JobType.smartSelfieEnrollment

    @IBOutlet var versionLabel: CopyableLabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        let partnerID = SmileIdentity.configuration.partnerId
        versionLabel.text = "Partner \(partnerID) - Version \(VersionNames().version)"
    }

    @IBAction func onEnvironmentToggle(_ sender: UIBarButtonItem) {
        if sender.title!.lowercased() == "sandbox" {
            SmileIdentity.setEnvironment(useSandbox: false)
            sender.title = "Production"
        } else {
            SmileIdentity.setEnvironment(useSandbox: true)
            sender.title = "Sandbox"
        }
    }

    @IBAction func onSmartSelfieRegistrationTap(_ sender: Any) {
        userID = UUID().uuidString
        currentJob = .smartSelfieEnrollment
        let smartSelfieRegistrationScreen = SmileIdentity.smartSelfieRegistrationScreen(userId: userID,
                                                                                        delegate: self)
        cameraVC = UIHostingController(rootView: smartSelfieRegistrationScreen)
        cameraVC?.modalPresentationStyle = .fullScreen
        navigationController?.present(cameraVC!, animated: true)
    }

    @IBAction func onSmartSelfieAuthenticationTap(_ sender: Any) {
        currentJob = .smartSelfieAuthentication
        if let userIDController = storyboard?.instantiateViewController(withIdentifier: "UserIDViewController")
            as? UserIDViewController {
            userIDController.userID = userID
            userIDController.handleContinueTap = { [weak self] userid in
                self?.smartSelfieAuthenticationScreen(userID: userid)
            }
            navigationController?.pushViewController(userIDController, animated: true)
        }
    }

    func smartSelfieAuthenticationScreen(userID: String) {
        let smartSelfieAuthenticationScreen = SmileIdentity.smartSelfieAuthenticationScreen(userId: userID,
                                                                                            delegate: self)
        cameraVC = UIHostingController(rootView: smartSelfieAuthenticationScreen)
        cameraVC?.modalPresentationStyle = .fullScreen
        navigationController?.present(cameraVC!, animated: true)
    }

    func didSucceed(selfieImage: Data, livenessImages: [Data], jobStatusResponse: JobStatusResponse) {
        cameraVC?.dismiss(animated: true, completion: {

            switch self.currentJob {
            case .smartSelfieEnrollment:
                UIPasteboard.general.string = self.userID
                self.presentAlert(title: "Smart Selfie Enrollment Complete",
                                  message: "The user has been registered and the user id has been copied to the clipboard.")
            case .smartSelfieAuthentication:
                self.presentAlert(title: "Smart Selfie Authentication Complete",
                                  message: "The user has been authenticated succesfully")
                self.navigationController?.popViewController(animated: true)
            default:
                break
            }
        })
    }

    func presentAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addAction(.init(title: "Okay", style: .default))
        self.navigationController?.present(alertController, animated: true)
    }

    func didError(error: Error) {
        presentAlert(title: "An error occured", message: error.localizedDescription)
    }
}
