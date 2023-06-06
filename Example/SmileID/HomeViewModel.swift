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
                presentSmartSelfieEnrolment = true
            case .smartSelfieAuthentication:
                presentSmartSelfieAuth = true
                presentSmartSelfieEnrolment = false
            default:
                presentSmartSelfieAuth = false
                presentSmartSelfieEnrolment = false
            }
        }
    }
    @Published var presentSmartSelfieAuth = false
    @Published var presentSmartSelfieEnrolment = false
    @Published var dismissed = false
    @Published var toastMessage = ""
    @Published var showToast = false


    private var userID = ""
    var returnedUserID = ""

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

    func didSucceed(selfieImage: Data, livenessImages: [Data], jobStatusResponse: JobStatusResponse) {
        returnedUserID = userID
        UIPasteboard.general.string = returnedUserID
        toastMessage = "Smart selfie enrollment completed successfully and the user id has beed copied to the clipboard"
        showToast = true
    }

    func didError(error: Error) {
        toastMessage = error.localizedDescription
        showToast = true
    }
}
