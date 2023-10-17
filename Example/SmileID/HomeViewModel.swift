import Foundation
import Combine
import UIKit
import SmileID

class HomeViewModel: ObservableObject,
    SmartSelfieResultDelegate,
    DocumentVerificationResultDelegate,
    EnhancedDocumentVerificationResultDelegate {

    @Published var dismissed = false
    @Published var toastMessage = ""
    @Published var showToast = false

    var returnedUserID = ""

    init() {
        subscribeToAuthCompletion()
    }

    @objc func didError(error: Error) {
        UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true)
        toastMessage = error.localizedDescription
        showToast = true
    }

    func didSucceed(
        selfieImage: URL,
        livenessImages: [URL],
        jobStatusResponse: JobStatusResponse<SmartSelfieJobResult>
    ) {
        UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true)
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

    func didSucceed(
        selfie: URL,
        documentFrontImage: URL,
        documentBackImage: URL?,
        jobStatusResponse: JobStatusResponse<DocumentVerificationJobResult>
    ) {
        UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true)
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
        UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true)
        showToast = true
        toastMessage = "Enhanced Document Verification submitted successfully, results processing"
        print("Document Verification jobStatusResponse: \(jobStatusResponse)")
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
