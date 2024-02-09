import Combine
import Foundation
import Sentry
import SmileID
import SwiftUI
import UIKit

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
    @ObservedObject var networkMonitor = NetworkMonitor.shared

    init(config: Config) {
        partnerId = config.partnerId
        SmileID.initialize(config: config, useSandbox: false)
        SentrySDK.configureScope { scope in
            scope.setTag(value: "partner_id", key: self.partnerId)
            let user = User()
            user.email = self.partnerId
            scope.setUser(user)
        }
    }

    func onProductClicked() {
        if !networkMonitor.isConnected {
            toastMessage = "No internet connection"
            showToast = true
        }
    }

    @objc func didError(error: Error) {
        dismissModal()
        showToast = true
        toastMessage = error.localizedDescription
    }

    // Called for SmartSelfie Enrollment by a proxy delegate in HomeView
    func onSmartSelfieEnrollment(
        userId: String,
        selfieImage _: URL,
        livenessImages _: [URL],
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
        selfieImage _: URL,
        livenessImages _: [URL],
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
        selfieImage _: URL,
        livenessImages _: [URL],
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
        selfie _: URL,
        documentFrontImage _: URL,
        documentBackImage _: URL?,
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
        selfie _: URL,
        documentFrontImage _: URL,
        documentBackImage _: URL?,
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
