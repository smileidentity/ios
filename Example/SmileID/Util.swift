import Foundation
import SmileID
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
    didSubmitJob: Bool? = nil,
    apiResponse: SmartSelfieResponse? = nil,
    suffix: String? = nil
) -> String {
    var message = "\(jobName) "
    if let didSubmitJob = didSubmitJob {
        if didSubmitJob {
            message += "completed successfully"
        } else {
            message += "saved offline"
        }
    } else {
        if let apiResponse = apiResponse {
            message += apiResponse.message
        }
    }
    if didSubmitJob == true {
        message += "completed successfully"
    } else {
        message += "saved offline"
    }
    if let suffix {
        message += ". \(suffix)"
    }
    return message
}
