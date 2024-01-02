import Combine
import SwiftUI

struct OrchestratedBiometricKycScreen: View {
    let userId: String
    let jobId: String
    let allowNewEnroll: Bool
    let showInstructions: Bool
    let showAttribution: Bool
    let allowAgentMode: Bool
    let extraPartnerParams: [String: String] = [:]
    let delegate: BiometricKycResultDelegate
    @ObservedObject private var viewModel: OrchestratedBiometricKycViewModel

    init(
        idInfo: IdInfo,
        userId: String,
        jobId: String,
        allowNewEnroll: Bool,
        showInstructions: Bool,
        showAttribution: Bool,
        allowAgentMode: Bool,
        extraPartnerParams: [String: String] = [:],
        delegate: BiometricKycResultDelegate
    ) {
        self.userId = userId
        self.jobId = jobId
        self.allowNewEnroll = allowNewEnroll
        self.showInstructions = showInstructions
        self.showAttribution = showAttribution
        self.allowAgentMode = allowAgentMode
        self.delegate = delegate
        viewModel = OrchestratedBiometricKycViewModel(
            userId: userId, jobId: jobId, allowNewEnroll: allowNewEnroll,  idInfo: idInfo, extraPartnerParams: extraPartnerParams
        )
    }

    var body: some View {
        switch viewModel.step {
        case .selfie:
            SelfieCaptureView(
                viewModel: SelfieCaptureViewModel(
                    userId: userId,
                    jobId: jobId,
                    isEnroll: false,
                    allowNewEnroll: allowNewEnroll,
                    shouldSubmitJob: false,
                    // imageCaptureDelegate is just for image capture, not job result
                    imageCaptureDelegate: viewModel
                ),
                delegate: nil
            )
        case .processing(let state):
            ProcessingScreen(
                processingState: state,
                inProgressTitle: SmileIDResourcesHelper.localizedString(
                    for: "BiometricKYC.Processing.Title"
                ),
                inProgressSubtitle: SmileIDResourcesHelper.localizedString(
                    for: "BiometricKYC.Processing.Subtitle"
                ),
                inProgressIcon: SmileIDResourcesHelper.DocumentProcessing,
                successTitle: SmileIDResourcesHelper.localizedString(
                    for: "BiometricKYC.Success.Title"
                ),
                successSubtitle: SmileIDResourcesHelper.localizedString(
                    for: "BiometricKYC.Success.Subtitle"
                ),
                successIcon: SmileIDResourcesHelper.CheckBold,
                errorTitle: SmileIDResourcesHelper.localizedString(for: "BiometricKYC.Error.Title"),
                errorSubtitle: SmileIDResourcesHelper.localizedString(
                    for: "BiometricKYC.Error.Subtitle"
                ),
                errorIcon: SmileIDResourcesHelper.Scan,
                continueButtonText: SmileIDResourcesHelper.localizedString(
                    for: "Confirmation.Continue"
                ),
                onContinue: { viewModel.onFinished(delegate: delegate) },
                retryButtonText: SmileIDResourcesHelper.localizedString(for: "Confirmation.Retry"),
                onRetry: viewModel.onRetry,
                closeButtonText: SmileIDResourcesHelper.localizedString(for: "Confirmation.Close"),
                onClose: { viewModel.onFinished(delegate: delegate) }
            )
        }
    }
}
