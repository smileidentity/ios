import SwiftUI

struct OrchestratedDocumentVerificationScreen: View {
    let countryCode: String
    let documentType: String?
    let captureBothSides: Bool
    let idAspectRatio: Double?
    let bypassSelfieCaptureWithFile: URL?
    let userId: String
    let jobId: String
    let allowNewEnroll: Bool
    let showAttribution: Bool
    let allowGalleryUpload: Bool
    let allowAgentMode: Bool
    let showInstructions: Bool
    let extraPartnerParams: [String: String]
    let onResult: DocumentVerificationResultDelegate

    var body: some View {
        IOrchestratedDocumentVerificationScreen(
            countryCode: countryCode,
            documentType: documentType,
            captureBothSides: captureBothSides,
            idAspectRatio: idAspectRatio,
            bypassSelfieCaptureWithFile: bypassSelfieCaptureWithFile,
            userId: userId,
            jobId: jobId,
            allowNewEnroll: allowNewEnroll,
            showAttribution: showAttribution,
            allowGalleryUpload: allowGalleryUpload,
            allowAgentMode: allowAgentMode,
            showInstructions: showInstructions,
            extraPartnerParams: extraPartnerParams,
            onResult: onResult,
            viewModel: OrchestratedDocumentVerificationViewModel(
                userId: userId,
                jobId: jobId,
                allowNewEnroll: allowNewEnroll,
                countryCode: countryCode,
                documentType: documentType,
                captureBothSides: captureBothSides,
                selfieFile: bypassSelfieCaptureWithFile,
                jobType: .documentVerification,
                extraPartnerParams: extraPartnerParams
            )
        )
    }
}

struct OrchestratedEnhancedDocumentVerificationScreen: View {
    let countryCode: String
    let documentType: String?
    let captureBothSides: Bool
    let idAspectRatio: Double?
    let bypassSelfieCaptureWithFile: URL?
    let userId: String
    let jobId: String
    let allowNewEnroll: Bool
    let showAttribution: Bool
    let allowGalleryUpload: Bool
    let allowAgentMode: Bool
    let showInstructions: Bool
    let extraPartnerParams: [String: String]
    let onResult: EnhancedDocumentVerificationResultDelegate

    var body: some View {
        IOrchestratedDocumentVerificationScreen(
            countryCode: countryCode,
            documentType: documentType,
            captureBothSides: captureBothSides,
            idAspectRatio: idAspectRatio,
            bypassSelfieCaptureWithFile: bypassSelfieCaptureWithFile,
            userId: userId,
            jobId: jobId,
            allowNewEnroll: allowNewEnroll,
            showAttribution: showAttribution,
            allowGalleryUpload: allowGalleryUpload,
            allowAgentMode: allowAgentMode,
            showInstructions: showInstructions,
            extraPartnerParams: extraPartnerParams,
            onResult: onResult,
            viewModel: OrchestratedEnhancedDocumentVerificationViewModel(
                userId: userId,
                jobId: jobId,
                allowNewEnroll: allowNewEnroll,
                countryCode: countryCode,
                documentType: documentType,
                captureBothSides: captureBothSides,
                selfieFile: bypassSelfieCaptureWithFile,
                jobType: .enhancedDocumentVerification,
                extraPartnerParams: extraPartnerParams
            )
        )
    }
}

private struct IOrchestratedDocumentVerificationScreen<T, U: JobResult>: View {
    let countryCode: String
    let documentType: String?
    let captureBothSides: Bool
    let idAspectRatio: Double?
    let bypassSelfieCaptureWithFile: URL?
    let userId: String
    let jobId: String
    let allowNewEnroll: Bool
    let showAttribution: Bool
    let allowGalleryUpload: Bool
    let allowAgentMode: Bool
    let showInstructions: Bool
    var extraPartnerParams: [String: String]
    let onResult: T
    @ObservedObject var viewModel: IOrchestratedDocumentVerificationViewModel<T, U>

    init(
        countryCode: String,
        documentType: String?,
        captureBothSides: Bool,
        idAspectRatio: Double?,
        bypassSelfieCaptureWithFile: URL?,
        userId: String,
        jobId: String,
        allowNewEnroll: Bool,
        showAttribution: Bool,
        allowGalleryUpload: Bool,
        allowAgentMode: Bool,
        showInstructions: Bool,
        extraPartnerParams: [String: String],
        onResult: T,
        viewModel: IOrchestratedDocumentVerificationViewModel<T, U>
    ) {
        self.countryCode = countryCode
        self.documentType = documentType
        self.captureBothSides = captureBothSides
        self.idAspectRatio = idAspectRatio
        self.bypassSelfieCaptureWithFile = bypassSelfieCaptureWithFile
        self.userId = userId
        self.jobId = jobId
        self.allowNewEnroll = allowNewEnroll
        self.showAttribution = showAttribution
        self.allowGalleryUpload = allowGalleryUpload
        self.allowAgentMode = allowAgentMode
        self.showInstructions = showInstructions
        self.extraPartnerParams = extraPartnerParams
        self.onResult = onResult
        self.viewModel = viewModel
    }

    var body: some View {
        switch viewModel.step {
        case .frontDocumentCapture:
            DocumentCaptureScreen(
                showInstructions: showInstructions,
                showAttribution: showAttribution,
                allowGallerySelection: allowGalleryUpload,
                showSkipButton: false,
                instructionsHeroImage: SmileIDResourcesHelper.DocVFrontHero,
                instructionsTitleText: SmileIDResourcesHelper.localizedString(
                    for: "Instructions.Document.Front.Header"
                ),
                instructionsSubtitleText: SmileIDResourcesHelper.localizedString(
                    for: "Instructions.Document.Front.Callout"
                ),
                captureTitleText: SmileIDResourcesHelper.localizedString(for: "Action.TakePhoto"),
                knownIdAspectRatio: idAspectRatio,
                onConfirm: { data, origin, retries in
                    viewModel.onFrontDocumentImageConfirmed(
                        documentImageFile: data,
                        imageOrigin: origin,
                        retryCount: retries
                    )
                },
                onError: viewModel.onError
            )
        case .backDocumentCapture:
            DocumentCaptureScreen(
                showInstructions: showInstructions,
                showAttribution: showAttribution,
                allowGallerySelection: allowGalleryUpload,
                showSkipButton: false,
                instructionsHeroImage: SmileIDResourcesHelper.DocVBackHero,
                instructionsTitleText: SmileIDResourcesHelper.localizedString(
                    for: "Instructions.Document.Back.Header"
                ),
                instructionsSubtitleText: SmileIDResourcesHelper.localizedString(
                    for: "Instructions.Document.Back.Callout"
                ),
                captureTitleText: SmileIDResourcesHelper.localizedString(for: "Action.TakePhoto"),
                knownIdAspectRatio: idAspectRatio,
                onConfirm: { data, origin, retries in
                    viewModel.onFrontDocumentImageConfirmed(
                        documentImageFile: data,
                        imageOrigin: origin,
                        retryCount: retries
                    )
                },
                onError: viewModel.onError,
                onSkip: viewModel.onDocumentBackSkip
            )
        case .selfieCapture:
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
}
