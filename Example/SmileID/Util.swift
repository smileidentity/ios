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
    jobComplete: Bool?,
    jobSuccess: Bool?,
    code: String?,
    resultCode: String?,
    resultText: String?,
    suffix: String? = nil
) -> String {
    var message = "\(jobName) "
    if jobComplete == true {
        if jobSuccess == true {
            message += "completed successfully"
        } else {
            message += "completed unsuccessfully"
        }
        message +=
            " (resultText=\(resultText ?? "null"), code=\(code ?? "null"), resultCode=\(resultCode ?? "null"))"
    } else {
        message += "still pending"
    }
    if let suffix = suffix {
        message += " \(suffix)"
    }
    return message
}
