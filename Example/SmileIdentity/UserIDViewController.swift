// swiftlint:disable force_cast
import UIKit

class UserIDViewController: UIViewController {
    var userID = ""
    @IBOutlet weak var userIdField: UITextField!
    var handleContinueTap: ((String) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        userIdField.text = userID
    }

    @IBAction func onContinueTap(_ sender: Any) {
        if  !userIdField.text!.isEmpty {
            handleContinueTap?(userIdField.text!)
        }
    }
}
