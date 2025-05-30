import Combine
import SwiftUI

struct OrchestratedBiometricKycScreen: View {
    let userId: String
    let jobId: String
    let allowNewEnroll: Bool
    let showInstructions: Bool
    let showAttribution: Bool
    let allowAgentMode: Bool
    let useStrictMode: Bool
    let extraPartnerParams: [String: String] = [:]
    let delegate: BiometricKycResultDelegate
    @Backport.StateObject private var viewModel: OrchestratedBiometricKycViewModel

    init(
        idInfo: IdInfo,
        consentInformation: ConsentInformation,
        userId: String,
        jobId: String,
        allowNewEnroll: Bool,
        showInstructions: Bool,
        showAttribution: Bool,
        allowAgentMode: Bool,
        useStrictMode: Bool,
        extraPartnerParams: [String: String] = [:],
        delegate: BiometricKycResultDelegate
    ) {
        self.userId = userId
        self.jobId = jobId
        self.allowNewEnroll = allowNewEnroll
        self.showInstructions = showInstructions
        self.showAttribution = showAttribution
        self.allowAgentMode = allowAgentMode
        self.useStrictMode = useStrictMode
        self.delegate = delegate
        self._viewModel = Backport.StateObject(wrappedValue: OrchestratedBiometricKycViewModel(
            userId: userId,
            jobId: jobId,
            allowNewEnroll: allowNewEnroll,
            idInfo: idInfo,
            useStrictMode: useStrictMode,
            consentInformation: consentInformation,
            extraPartnerParams: extraPartnerParams
        ))
    }

    var body: some View {
        ZStack {
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
        .onAppear {
            Metadata.shared.onStart()
        }
    }

    private var selfieCaptureScreen: some View {
        Group {
            if useStrictMode {
                OrchestratedEnhancedSelfieCaptureScreen(
                    userId: userId,
                    isEnroll: false,
                    allowNewEnroll: allowNewEnroll,
                    showAttribution: showAttribution,
                    showInstructions: showInstructions,
                    skipApiSubmission: true,
                    extraPartnerParams: extraPartnerParams,
                    onResult: viewModel
                )
            } else {
                OrchestratedSelfieCaptureScreen(
                    userId: userId,
                    jobId: jobId,
                    isEnroll: false,
                    allowNewEnroll: allowNewEnroll,
                    allowAgentMode: allowAgentMode,
                    showAttribution: showAttribution,
                    showInstructions: showInstructions,
                    extraPartnerParams: extraPartnerParams,
                    skipApiSubmission: true,
                    onResult: viewModel
                )
            }
        }
    }
}
