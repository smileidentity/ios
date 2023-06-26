import Foundation
import Combine
import UIKit
import SmileID

class HomeViewModel: ObservableObject, SmartSelfieResultDelegate {
    @Published var product: JobType? {
        didSet {
            switch product {
            case .smartSelfieEnrollment:
                presentSmartSelfieAuth = false
                presentSmartSelfieEnrollment = true
            case .smartSelfieAuthentication:
                presentSmartSelfieAuth = true
                presentSmartSelfieEnrollment = false
            default:
                presentSmartSelfieAuth = false
                presentSmartSelfieEnrollment = false
            }
        }
    }
    @Published var presentSmartSelfieAuth = false
    @Published var presentSmartSelfieEnrollment = false
    @Published var dismissed = false
    @Published var toastMessage = ""
    @Published var showToast = false


    private var userID = ""
    var returnedUserID = ""

    init() {
       subscribeToAuthCompletion()
    }

    func generateUserID() -> String {
        userID = UUID().uuidString
        return userID
    }

    func handleSmartSelfieEnrolmentTap() {
        self.product = .smartSelfieEnrollment
    }

    func handleSmartSelfieAuthTap() {
        self.product = .smartSelfieAuthentication
    }

    func didSucceed(selfieImage: Data, livenessImages: [Data], jobStatusResponse: JobStatusResponse?) {
        returnedUserID = userID
        UIPasteboard.general.string = returnedUserID
        showToast = true
        if let jobStatusResponse = jobStatusResponse {
            if jobStatusResponse.jobSuccess {
                toastMessage = "Smart selfie enrollment completed successfully and the user id has beed copied to the clipboard"
            } else {
                toastMessage = "Job submitted successfully, results processing"
            }
        } else {
            toastMessage = "Job submitted successfully, results processing"
        }
    }

    @objc func didError(error: Error) {
        toastMessage = error.localizedDescription
        showToast = true
    }

    func subscribeToAuthCompletion() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleAuthCompletion), name: Notification.Name(rawValue: "SelfieCaptureComplete"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAuthCompletion), name: Notification.Name(rawValue: "SelfieCaptureError"), object: nil)
    }

    @objc func handleAuthCompletion(_ notification: NSNotification) {
        if let dict =  notification.userInfo as? NSDictionary {
            showToast = true
            if let error = dict["Error"] as? Error {
                toastMessage = error.localizedDescription
                return
            }
            if let response = dict["Response"] as? JobStatusResponse {
                if response.jobSuccess == true {
                    toastMessage = "Smart Selfie Authentication completed successfully"
                    return
                }

                if response.jobComplete == false {
                    toastMessage = "Job submitted successfully, results processing"
                    return
                }
            } else {
                toastMessage = "Job submitted successfully, results processing"
                return
            }
        }
        else {
            toastMessage = "Job submitted successfully, results processing"
            return
        }
    }
}
