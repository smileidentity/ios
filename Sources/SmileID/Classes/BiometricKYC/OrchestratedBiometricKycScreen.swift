import Combine
import SwiftUI

struct OrchestratedBiometricKycScreen: View {
    let config: BiometricVerificationConfig
    let delegate: BiometricKycResultDelegate
    @Backport.StateObject private var viewModel: OrchestratedBiometricKycViewModel

    init(
        config: BiometricVerificationConfig,
        delegate: BiometricKycResultDelegate
    ) {
        self.config = config
        self.delegate = delegate
        self._viewModel = Backport.StateObject(wrappedValue: OrchestratedBiometricKycViewModel(
            config: config
        ))
    }

    var body: some View {
        switch viewModel.step {
        case .selfie:
            selfieCaptureScreen
        case let .processing(state):
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
                errorSubtitle: getErrorSubtitle(
                    errorMessageRes: $viewModel.errorMessageRes.wrappedValue,
                    errorMessage: $viewModel.errorMessage.wrappedValue
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

    private var selfieCaptureScreen: some View {
        Group {
            if config.useStrictMode {
                OrchestratedEnhancedSelfieCaptureScreen(
                    config: OrchestratedSelfieCaptureConfig(
                        userId: config.userId,
                        isEnroll: false,
                        allowNewEnroll: config.allowNewEnroll,
                        showAttribution: config.showAttribution,
                        showInstructions: config.showInstructions,
                        extraPartnerParams: config.extraPartnerParams,
                        skipApiSubmission: true
                    ),
                    onResult: viewModel
                )
            } else {
                OrchestratedSelfieCaptureScreen(
                    config: OrchestratedSelfieCaptureConfig(
                        userId: config.userId,
                        jobId: config.jobId,
                        isEnroll: false,
                        allowNewEnroll: config.allowNewEnroll,
                        allowAgentMode: config.allowAgentMode,
                        showAttribution: config.showAttribution,
                        showInstructions: config.showInstructions,
                        extraPartnerParams: config.extraPartnerParams,
                        skipApiSubmission: true
                    ),
                    onResult: viewModel
                )
            }
        }
    }
}
