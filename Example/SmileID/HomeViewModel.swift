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

    var returnedUserID: String?

    @objc func didError(error: Error) {
        dismissModal()
        showToast = true
        toastMessage = error.localizedDescription
    }

    func didSucceed(
        selfieImage: URL,
        livenessImages: [URL],
        jobStatusResponse: JobStatusResponse<SmartSelfieJobResult>
    ) {
        dismissModal()
        showToast = true
        let partnerParams = jobStatusResponse.result?.partnerParams
        if partnerParams?.jobType == .smartSelfieEnrollment {
            returnedUserID = partnerParams?.userId
            UIPasteboard.general.string = returnedUserID
            toastMessage = jobResultMessageBuilder(
                jobName: "SmartSelfie Enrollment",
                jobComplete: jobStatusResponse.jobComplete,
                jobSuccess: jobStatusResponse.jobSuccess,
                code: jobStatusResponse.code,
                resultCode: jobStatusResponse.result?.resultCode,
                resultText: jobStatusResponse.result?.resultText,
                suffix: "The User ID has been copied to your clipboard"
            )
        } else {
            toastMessage = jobResultMessageBuilder(
                jobName: "SmartSelfie Authentication",
                jobComplete: jobStatusResponse.jobComplete,
                jobSuccess: jobStatusResponse.jobSuccess,
                code: jobStatusResponse.code,
                resultCode: jobStatusResponse.result?.resultCode,
                resultText: jobStatusResponse.result?.resultText
            )
        }
    }

    func didSucceed(
        selfie: URL,
        documentFrontImage: URL,
        documentBackImage: URL?,
        jobStatusResponse: JobStatusResponse<DocumentVerificationJobResult>
    ) {
        dismissModal()
        showToast = true
        toastMessage = jobResultMessageBuilder(
            jobName: "Document Verification",
            jobComplete: jobStatusResponse.jobComplete,
            jobSuccess: jobStatusResponse.jobSuccess,
            code: jobStatusResponse.code,
            resultCode: jobStatusResponse.result?.resultCode,
            resultText: jobStatusResponse.result?.resultText
        )
    }

    func didSucceed(
        selfie: URL,
        documentFrontImage: URL,
        documentBackImage: URL?,
        jobStatusResponse: JobStatusResponse<EnhancedDocumentVerificationJobResult>
    ) {
        dismissModal()
        showToast = true
        toastMessage = jobResultMessageBuilder(
            jobName: "Enhanced Document Verification",
            jobComplete: jobStatusResponse.jobComplete,
            jobSuccess: jobStatusResponse.jobSuccess,
            code: jobStatusResponse.code,
            resultCode: jobStatusResponse.result?.resultCode,
            resultText: jobStatusResponse.result?.resultText
        )
    }

    func onConsentGranted() {
        dismissModal()
        showToast = true
        toastMessage = "Consent Granted"
    }

    func onConsentDenied() {
        dismissModal()
        showToast = true
        toastMessage = "Consent Denied"
    }

    private func dismissModal() {
        UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true)
    }
}
