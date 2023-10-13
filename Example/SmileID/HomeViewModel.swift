import Foundation
import Combine
import UIKit
import SmileID

class HomeViewModel: ObservableObject,
    SmartSelfieResultDelegate,
    DocumentVerificationResultDelegate,
    EnhancedDocumentVerificationResultDelegate {
    @Published var product: JobType? {
        didSet {
            switch product {
            case .smartSelfieEnrollment:
                presentSmartSelfieAuth = false
                presentSmartSelfieEnrollment = true
                presentDocumentVerification = false
                presentEnhancedDocumentVerification = false
            case .smartSelfieAuthentication:
                presentSmartSelfieAuth = true
                presentSmartSelfieEnrollment = false
                presentDocumentVerification = false
                presentEnhancedDocumentVerification = false
            case .documentVerification:
                presentSmartSelfieAuth = false
                presentSmartSelfieEnrollment = false
                presentDocumentVerification = true
                presentEnhancedDocumentVerification = false
            case .enhancedDocumentVerification:
                presentSmartSelfieAuth = false
                presentSmartSelfieEnrollment = false
                presentDocumentVerification = false
                presentEnhancedDocumentVerification = true
            default:
                presentSmartSelfieAuth = false
                presentSmartSelfieEnrollment = false
                presentDocumentVerification = false
                presentEnhancedDocumentVerification = false
            }
        }
    }
    @Published var presentSmartSelfieAuth = false
    @Published var presentSmartSelfieEnrollment = false
    @Published var presentDocumentVerification = false
    @Published var presentEnhancedDocumentVerification = false
    @Published var dismissed = false
    @Published var toastMessage = ""
    @Published var showToast = false

    var returnedUserID = ""

    init() {
        subscribeToAuthCompletion()
    }

    func handleSmartSelfieEnrolmentTap() {
        product = .smartSelfieEnrollment
    }

    func handleSmartSelfieAuthTap() {
        product = .smartSelfieAuthentication
    }

    func handleDocumentVerificationTap() {
        product = .documentVerification
    }

    func handleEnhancedDocumentVerificationTap() {
        product = .enhancedDocumentVerification
    }

    func didSucceed(
        selfieImage: URL,
        livenessImages: [URL],
        jobStatusResponse: JobStatusResponse<SmartSelfieJobResult>
    ) {
        returnedUserID = jobStatusResponse.result?.partnerParams.userId ?? ""
        UIPasteboard.general.string = returnedUserID
        showToast = true
        if jobStatusResponse.jobSuccess {
            toastMessage = """
                           SmartSelfie Enrollment completed successfully. User ID has been copied to
                            the clipboard
                           """
        } else {
            toastMessage = "Job submitted successfully, results processing"
        }
    }

    @objc func didError(error: Error) {
        toastMessage = error.localizedDescription
        showToast = true
    }

    func subscribeToAuthCompletion() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthCompletion),
            name: Notification.Name(rawValue: "SelfieCaptureComplete"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthCompletion),
            name: Notification.Name(rawValue: "SelfieCaptureError"),
            object: nil
        )
    }

    func didSucceed(
        selfie: URL,
        documentFrontImage: URL,
        documentBackImage: URL?,
        jobStatusResponse: JobStatusResponse<DocumentVerificationJobResult>
    ) {
        showToast = true
        toastMessage = "Document Verification submitted successfully, results processing"
        print("Document Verification jobStatusResponse: \(jobStatusResponse)")
    }

    func didSucceed(
        selfie: URL,
        documentFrontImage: URL,
        documentBackImage: URL?,
        jobStatusResponse: JobStatusResponse<EnhancedDocumentVerificationJobResult>
    ) {
        showToast = true
        toastMessage = "Enhanced Document Verification submitted successfully, results processing"
        print("Document Verification jobStatusResponse: \(jobStatusResponse)")
    }

    @objc func handleAuthCompletion(_ notification: NSNotification) {
        if let dict = notification.userInfo as? NSDictionary {
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
        } else {
            toastMessage = "Job submitted successfully, results processing"
            return
        }
    }
}
