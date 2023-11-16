import Combine
import SwiftUI

struct OrchestratedBiometricKycScreen: View {
    let userId: String
    let jobId: String
    let showInstructions: Bool
    let showAttribution: Bool
    let allowAgentMode: Bool
    let delegate: BiometricKycResultDelegate
    @ObservedObject private var viewModel: OrchestratedBiometricKycViewModel

    init(
        idInfo: IdInfo,
        userId: String,
        jobId: String,
        showInstructions: Bool,
        showAttribution: Bool,
        allowAgentMode: Bool,
        partnerParams: [String: String] = [:],
        delegate: BiometricKycResultDelegate
    ) {
        self.userId = userId
        self.jobId = jobId
        self.showInstructions = showInstructions
        self.showAttribution = showAttribution
        self.allowAgentMode = allowAgentMode
        self.delegate = delegate
        viewModel = OrchestratedBiometricKycViewModel(
            userId: userId, jobId: jobId, idInfo: idInfo, partnerParams: partnerParams
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
