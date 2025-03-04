import SwiftUI

struct IOrchestratedDocumentVerificationScreen<T, U: JobResult>: View {
    let config: DocumentVerificationConfig
    let onResult: T
    @Backport.StateObject var viewModel: IOrchestratedDocumentVerificationViewModel<T, U>
    @State private var showSelfieCaptureInstructions: Bool

    init(
        config: DocumentVerificationConfig,
        onResult: T,
        viewModel: IOrchestratedDocumentVerificationViewModel<T, U>
    ) {
        self.config = config
        self.onResult = onResult
        self._viewModel = Backport.StateObject(wrappedValue: viewModel)
        self._showSelfieCaptureInstructions = State(initialValue: config.showInstructions)
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
                captureTitleText: SmileIDResourcesHelper.localizedString(
                    for: "Action.CaptureFront"),
                knownIdAspectRatio: config.idAspectRatio,
                onConfirm: viewModel.onFrontDocumentImageConfirmed,
                onError: viewModel.onError
            )
            .transition(.move(edge: .leading))
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
            .transition(.move(edge: .trailing))
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
            .transition(.move(edge: .trailing))
        }
    }

    private var selfieCaptureScreen: some View {
        ZStack {
            if config.useStrictMode {
                if showSelfieCaptureInstructions {
                    LivenessCaptureInstructionsView(
                        showAttribution: config.showAttribution,
                        didTapGetStarted: {
                            withAnimation { showSelfieCaptureInstructions = false }
                        }
                    )
                    .transition(.move(edge: .leading))
                } else {
                    EnhancedSelfieCaptureScreen(
                        userId: config.userId,
                        showAttribution: config.showAttribution,
                        delegate: viewModel
                    )
                    .transition(.move(edge: .trailing))
                }
            } else {
                if showSelfieCaptureInstructions {
                    SmartSelfieInstructionsScreen(
                        showAttribution: config.showAttribution,
                        didTapTakePhoto: {
                            withAnimation { showSelfieCaptureInstructions = false }
                        }
                    )
                    .transition(.move(edge: .leading))
                } else {
                    SelfieCaptureScreen(
                        jobId: config.jobId,
                        delegate: viewModel
                    )
                    .transition(.move(edge: .trailing))
                }
            }
        }
    }
}
