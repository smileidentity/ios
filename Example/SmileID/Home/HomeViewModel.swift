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

    @Published private(set) var smartSelfieEnrollmentUserId = generateUserId()
    var newJobId: String {
        generateJobId()
    }

    let dataStoreClient: DataStoreClient

    init(
        config: Config,
        dataStoreClient: DataStoreClient = DataStoreClient()
    ) {
        self.dataStoreClient = dataStoreClient
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

    private func showToast(message: String) {
        toastMessage = message
        showToast = true
    }

    // Called for SmartSelfie Enrollment by a proxy delegate in HomeView
    func onSmartSelfieEnrollment(
        userId: String,
        selfieImage: URL,
        livenessImages _: [URL],
        apiResponse: SmartSelfieResponse?
    ) {
        dismissModal()
        showToast = true
        UIPasteboard.general.string = userId
        toastMessage = jobResultMessageBuilder(
            jobName: "SmartSelfie Enrollment",
            apiResponse: apiResponse,
            suffix: "The User ID has been copied to your clipboard"
        )
        if let apiResponse = apiResponse {
            do {
                try dataStoreClient.saveJob(
                    data: JobData(
                        jobType: .smartSelfieEnrollment,
                        timestamp: apiResponse.createdAt.jobTimestampDate(),
                        userId: apiResponse.userId,
                        jobId: apiResponse.jobId,
                        jobComplete: true,
                        jobSuccess: apiResponse.status == .approved,
                        code: apiResponse.code,
                        resultCode: apiResponse.code,
                        smileJobId: apiResponse.jobId,
                        resultText: apiResponse.message,
                        selfieImageUrl: selfieImage.absoluteString
                    )
                )
            } catch {
                showToast(message: error.localizedDescription)
            }
        }
    }

    // Called only for SmartSelfie Authentication
    func didSucceed(
        selfieImage: URL,
        livenessImages _: [URL],
        apiResponse: SmartSelfieResponse?
    ) {
        dismissModal()
        showToast = true
        toastMessage = jobResultMessageBuilder(
            jobName: "SmartSelfie Authentication",
            apiResponse: apiResponse
        )
        if let apiResponse = apiResponse {
            do {
                try dataStoreClient.saveJob(
                    data: JobData(
                        jobType: .smartSelfieAuthentication,
                        timestamp: apiResponse.createdAt.jobTimestampDate(),
                        userId: apiResponse.userId,
                        jobId: apiResponse.jobId,
                        jobComplete: true,
                        jobSuccess: apiResponse.status == .approved,
                        code: apiResponse.code,
                        resultCode: apiResponse.code,
                        smileJobId: apiResponse.jobId,
                        resultText: apiResponse.message,
                        selfieImageUrl: selfieImage.absoluteString
                    )
                )
            } catch {
                showToast(message: error.localizedDescription)
            }
        }
    }

    func didSucceed(
        selfieImage _: URL,
        livenessImages _: [URL],
        didSubmitBiometricJob: Bool
    ) {
        dismissModal()
        showToast = true
        toastMessage = jobResultMessageBuilder(
            jobName: "Biometric KYC",
            didSubmitJob: didSubmitBiometricJob
        )
        do {
            try dataStoreClient.saveJob(
                data: JobData(
                    jobType: .biometricKyc,
                    timestamp: Date(),
                    userId: smartSelfieEnrollmentUserId,
                    jobId: newJobId
                )
            )
        } catch {
            showToast(message: error.localizedDescription)
        }
    }

    func didSucceed(
        enhancedKycResponse: EnhancedKycResponse
    ) {
        dismissModal()
        showToast = true
        toastMessage = jobResultMessageBuilder(
            jobName: "Enhanced KYC",
            didSubmitJob: true
        )
        do {
            try dataStoreClient.saveJob(
                data: JobData(
                    jobType: .enhancedKyc,
                    timestamp: Date(),
                    userId: enhancedKycResponse.partnerParams.userId,
                    jobId: enhancedKycResponse.partnerParams.jobId,
                    jobComplete: true,
                    jobSuccess: true,
                    resultCode: enhancedKycResponse.resultCode,
                    smileJobId: enhancedKycResponse.smileJobId,
                    resultText: enhancedKycResponse.resultText
                )
            )
        } catch {
            showToast(message: error.localizedDescription)
        }
    }

    func didSucceed(
        selfie _: URL,
        documentFrontImage _: URL,
        documentBackImage _: URL?,
        didSubmitDocumentVerificationJob: Bool
    ) {
        dismissModal()
        showToast = true
        toastMessage = jobResultMessageBuilder(
            jobName: "Document Verification",
            didSubmitJob: didSubmitDocumentVerificationJob
        )
        do {
            try dataStoreClient.saveJob(
                data: JobData(
                    jobType: .documentVerification,
                    timestamp: Date(),
                    userId: smartSelfieEnrollmentUserId,
                    jobId: newJobId
                )
            )
        } catch {
            showToast(message: error.localizedDescription)
        }
    }

    func didSucceed(
        selfie _: URL,
        documentFrontImage _: URL,
        documentBackImage _: URL?,
        didSubmitEnhancedDocVJob: Bool
    ) {
        dismissModal()
        showToast = true
        toastMessage = jobResultMessageBuilder(
            jobName: "Enhanced Document Verification",
            didSubmitJob: didSubmitEnhancedDocVJob
        )
        do {
            try dataStoreClient.saveJob(
                data: JobData(
                    jobType: .enhancedDocumentVerification,
                    timestamp: Date(),
                    userId: smartSelfieEnrollmentUserId,
                    jobId: newJobId
                )
            )
        } catch {
            showToast(message: error.localizedDescription)
        }
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
