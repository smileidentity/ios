import UIKit
import SwiftUI
import Combine
import SmileIdentity

class ViewController: UIViewController, SmartSelfieResult {
    var cameraVC: UIViewController?
    var cancellable: AnyCancellable?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func onSmartSelfieTap(_ sender: Any) {
        cameraVC = UIHostingController(rootView: SelfieCaptureView(delegate: self))
        navigationController?.present(cameraVC!, animated: true)
        authenticateUser()
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

    func authenticateUser() {
        let request = AuthenticationRequest(jobType: .smartSelfieEnrollment, enrollment: true, userId: "45839" )
        cancellable = SmileIdentity.api.authenticate(request: request)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("failure")
                    print((error as! APIError).description)
                }
            }, receiveValue: { response in
                print("Success!")
                print(response.success)
            })
    }

    func didError(error: Error) {

    }
}
