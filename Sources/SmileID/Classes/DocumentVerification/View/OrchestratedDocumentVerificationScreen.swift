import SwiftUI

struct OrchestratedDocumentVerificationScreen: View {
    @State private var localMetadata = LocalMetadata()
    let config: DocumentVerificationConfig
    let onResult: DocumentVerificationResultDelegate

    var body: some View {
        IOrchestratedDocumentVerificationScreen(
            config: config,
            onResult: onResult,
            viewModel: OrchestratedDocumentVerificationViewModel(
                config: config,
                jobType: .documentVerification,
                localMetadata: localMetadata
            )
        ).environmentObject(localMetadata)
    }
}

struct OrchestratedEnhancedDocumentVerificationScreen: View {
    @State private var localMetadata = LocalMetadata()
    let config: DocumentVerificationConfig
    let onResult: EnhancedDocumentVerificationResultDelegate

    var body: some View {
        IOrchestratedDocumentVerificationScreen(
            config: config,
            onResult: onResult,
            viewModel: OrchestratedEnhancedDocumentVerificationViewModel(
                config: config,
                jobType: .enhancedDocumentVerification,
                localMetadata: localMetadata
            )
        ).environmentObject(localMetadata)
    }
}

private struct IOrchestratedDocumentVerificationScreen<T, U: JobResult>: View {
    let config: DocumentVerificationConfig
    let onResult: T
    @Backport.StateObject var viewModel: IOrchestratedDocumentVerificationViewModel<T, U>

    init(
        config: DocumentVerificationConfig,
        onResult: T,
        viewModel: IOrchestratedDocumentVerificationViewModel<T, U>
    ) {
        self.config = config
        self.onResult = onResult
        self._viewModel = Backport.StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        switch viewModel.step {
        case .frontDocumentCapture:
            DocumentCaptureScreen(
                side: .front,
                showInstructions: config.showInstructions,
                showAttribution: config.showAttribution,
                allowGallerySelection: config.allowGalleryUpload,
                showSkipButton: false,
                instructionsHeroImage: SmileIDResourcesHelper.DocVFrontHero,
                instructionsTitleText: SmileIDResourcesHelper.localizedString(
                    for: "Instructions.Document.Front.Header"
                ),
                instructionsSubtitleText: SmileIDResourcesHelper.localizedString(
                    for: "Instructions.Document.Front.Callout"
                ),
                captureTitleText: SmileIDResourcesHelper.localizedString(for: "Action.CaptureFront"),
                knownIdAspectRatio: config.idAspectRatio,
                onConfirm: viewModel.onFrontDocumentImageConfirmed,
                onError: viewModel.onError
            )
        case .backDocumentCapture:
            DocumentCaptureScreen(
                side: .back,
                showInstructions: config.showInstructions,
                showAttribution: config.showAttribution,
                allowGallerySelection: config.allowGalleryUpload,
                showSkipButton: false,
                instructionsHeroImage: SmileIDResourcesHelper.DocVBackHero,
                instructionsTitleText: SmileIDResourcesHelper.localizedString(
                    for: "Instructions.Document.Back.Header"
                ),
                instructionsSubtitleText: SmileIDResourcesHelper.localizedString(
                    for: "Instructions.Document.Back.Callout"
                ),
                captureTitleText: SmileIDResourcesHelper.localizedString(for: "Action.CaptureBack"),
                knownIdAspectRatio: config.idAspectRatio,
                onConfirm: viewModel.onBackDocumentImageConfirmed,
                onError: viewModel.onError,
                onSkip: viewModel.onDocumentBackSkip
            )
        case .selfieCapture:
            selfieCaptureScreen
        case let .processing(state):
            ProcessingScreen(
                processingState: state,
                inProgressTitle: SmileIDResourcesHelper.localizedString(
                    for: "Document.Processing.Header"
                ),
                inProgressSubtitle: SmileIDResourcesHelper.localizedString(
                    for: "Document.Processing.Callout"
                ),
                inProgressIcon: SmileIDResourcesHelper.DocumentProcessing,
                successTitle: SmileIDResourcesHelper.localizedString(
                    for: "Document.Complete.Header"
                ),
                successSubtitle: SmileIDResourcesHelper.localizedString(
                    for: $viewModel.errorMessageRes.wrappedValue ?? "Document.Complete.Callout"
                ),
                successIcon: SmileIDResourcesHelper.CheckBold,
                errorTitle: SmileIDResourcesHelper.localizedString(for: "Document.Error.Header"),
                errorSubtitle: getErrorSubtitle(
                    errorMessageRes: $viewModel.errorMessageRes.wrappedValue,
                    errorMessage: $viewModel.errorMessage.wrappedValue
                ),
                errorIcon: SmileIDResourcesHelper.Scan,
                continueButtonText: SmileIDResourcesHelper.localizedString(
                    for: "Confirmation.Continue"
                ),
                onContinue: { viewModel.onFinished(delegate: onResult) },
                retryButtonText: SmileIDResourcesHelper.localizedString(for: "Confirmation.Retry"),
                onRetry: viewModel.onRetry,
                closeButtonText: SmileIDResourcesHelper.localizedString(for: "Confirmation.Close"),
                onClose: { viewModel.onFinished(delegate: onResult) }
            )
        }
    }

    private var selfieCaptureScreen: some View {
        Group {
            if config.useStrictMode {
                OrchestratedEnhancedSelfieCaptureScreen(
                    userId: config.userId,
                    isEnroll: false,
                    allowNewEnroll: config.allowNewEnroll,
                    showAttribution: config.showAttribution,
                    showInstructions: config.showInstructions,
                    skipApiSubmission: true,
                    extraPartnerParams: config.extraPartnerParams,
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
