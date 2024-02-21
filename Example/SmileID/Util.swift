import Foundation
import SwiftUI

func openUrl(_ urlString: String) {
    guard let url = URL(string: urlString) else {
        print("Invalid URL: \(urlString)")
        return
    }
    UIApplication.shared.open(url)
}

func jobResultMessageBuilder(
    jobName: String,
    didSubmitJob: Bool?,
    suffix: String? = nil
) -> String {
    var message = "\(jobName) "
    if didSubmitJob == true {
        message += "completed successfully"
    } else {
        message += "saved offline"
    }
    if let suffix = suffix {
        message += ". \(suffix)"
    }
    return message
}
