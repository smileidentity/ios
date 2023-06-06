import Foundation
import Combine
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

    }

    func didError(error: Error) {

    }
}
