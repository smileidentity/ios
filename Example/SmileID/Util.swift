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
  jobComplete: Bool? = false,
  jobSuccess: Bool? = false,
  code: String? = nil,
  resultCode: String? = nil,
  resultText: String? = nil,
  apiResponse: SmartSelfieResponse? = nil,
  suffix: String? = nil
) -> String {
  var message = "\(jobName) "
  if didSubmitJob == true {
    if jobComplete == true {
      if jobSuccess == true {
        message += "completed successfully"
      } else {
        message += "completed unsuccessfully"
      }
      var parenthesesTextComponents: [String] = []
      if let resultText, !resultText.isEmpty {
        parenthesesTextComponents.append("resultText=\(resultText)")
      }
      if let code, !code.isEmpty {
        parenthesesTextComponents.append("code=\(code)")
      }
      if let resultCode, !resultCode.isEmpty {
        parenthesesTextComponents.append("resultCode=\(resultCode)")
      }
      let parenthesesText = parenthesesTextComponents.joined(separator: ", ")
      if !parenthesesText.isEmpty {
        message += " (\(parenthesesText))"
      }
    } else {
      message += "still pending"
    }
  } else {
    if let apiResponse {
      message += apiResponse.message
    } else {
      message += "was saved offline and will need to be submitted later"
    }
  }
  if let suffix {
    message += " \(suffix)"
  }
  return message
}
