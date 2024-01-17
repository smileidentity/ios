import Foundation
import Combine
import UIKit
import SmileID

class HomeViewModel: ObservableObject,
    SmartSelfieResultDelegate,
    DocumentVerificationResultDelegate,
    EnhancedDocumentVerificationResultDelegate,
    EnhancedKycResultDelegate,
    BiometricKycResultDelegate {

    // MARK: - UI Properties
    @Published var dismissed = false
    @Published var toastMessage = ""
    @Published var showToast = false
    @Published var partnerId: String

    init(config: Config) {
        partnerId = config.partnerId
        SmileID.initialize(config: config, useSandbox: true)
    }

    @objc func didError(error: Error) {
        dismissModal()
        showToast = true
        toastMessage = error.localizedDescription
    }

    // Called for SmartSelfie Enrollment by a proxy delegate in HomeView
    func onSmartSelfieEnrollment(
        userId: String,
        selfieImage: URL,
        livenessImages: [URL],
        jobStatusResponse: JobStatusResponse<SmartSelfieJobResult>?
    ) {
        dismissModal()
        showToast = true
        UIPasteboard.general.string = userId
        toastMessage = jobResultMessageBuilder(
            jobName: "SmartSelfie Enrollment",
            jobComplete: jobStatusResponse?.jobComplete,
            jobSuccess: jobStatusResponse?.jobSuccess,
            code: jobStatusResponse?.code,
            resultCode: jobStatusResponse?.result?.resultCode,
            resultText: jobStatusResponse?.result?.resultText,
            suffix: "The User ID has been copied to your clipboard"
        )
    }

    // Called only for SmartSelfie Authentication
    func didSucceed(
        selfieImage: URL,
        livenessImages: [URL],
        jobStatusResponse: JobStatusResponse<SmartSelfieJobResult>?
    ) {
        dismissModal()
        showToast = true
        toastMessage = jobResultMessageBuilder(
            jobName: "SmartSelfie Authentication",
            jobComplete: jobStatusResponse?.jobComplete,
            jobSuccess: jobStatusResponse?.jobSuccess,
            code: jobStatusResponse?.code,
            resultCode: jobStatusResponse?.result?.resultCode,
            resultText: jobStatusResponse?.result?.resultText
        )
    }

    func didSucceed(
        selfieImage: URL,
        livenessImages: [URL],
        jobStatusResponse: JobStatusResponse<BiometricKycJobResult>
    ) {
        dismissModal()
        showToast = true
        toastMessage = jobResultMessageBuilder(
            jobName: "Biometric KYC",
            jobComplete: jobStatusResponse.jobComplete,
            jobSuccess: jobStatusResponse.jobSuccess,
            code: jobStatusResponse.code,
            resultCode: jobStatusResponse.result?.resultCode,
            resultText: jobStatusResponse.result?.resultText
        )
    }
    
    func didSucceed(
        enhancedKycResponse: EnhancedKycResponse
    ) {
        dismissModal()
        showToast = true
        toastMessage = jobResultMessageBuilder(
            jobName: "Enhanced KYC",
            jobComplete: true,
            jobSuccess: true,
            code: nil,
            resultCode: enhancedKycResponse.resultCode,
            resultText: enhancedKycResponse.resultText
        )
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
