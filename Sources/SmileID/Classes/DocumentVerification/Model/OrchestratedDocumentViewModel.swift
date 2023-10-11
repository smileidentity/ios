import Foundation
import SwiftUI

enum DocumentProcessingState {
    case inProgress
    case success
    case error
}

enum DocumentCaptureFlow: Equatable {
    case frontDocumentCapture
    case backDocumentCapture
    case selfieCapture
    case processing(DocumentProcessingState)
}

// TODO: Remove
class SelfiePlaceHolderDelegate: SmartSelfieResultDelegate {
    func didSucceed(
        selfieImage _: URL,
        livenessImages _: [URL],
        jobStatusResponse _: JobStatusResponse
    ) {}

    func didError(error _: Error) {}
}

class OrchestratedDocumentViewModel: ObservableObject, SelfieImageCaptureDelegate {
    // Input properties
    private var userId: String
    private var jobId: String
    private var countryCode: String
    private var documentType: String?
    private var captureBothSides: Bool
    private var selfieFile: URL?

    // Other properties
    private var documentFrontFile: URL?
    private var documentBackFile: URL?
    private var livenessFiles: [URL]?
    private var jobStatusResponse: JobStatusResponse?
    private var stepToRetry: DocumentCaptureFlow?

    // UI properties
    // TODO: Mark these as @MainActor?
    @Published var step = DocumentCaptureFlow.frontDocumentCapture

    init(
        userId: String,
        jobId: String,
        countryCode: String,
        documentType: String?,
        captureBothSides: Bool,
        selfieFile: URL?
    ) {
        self.userId = userId
        self.jobId = jobId
        self.countryCode = countryCode
        self.documentType = documentType
        self.captureBothSides = captureBothSides
        self.selfieFile = selfieFile
    }

    func onFrontDocumentImageConfirmed(data: Data) {
        guard let file = try? LocalStorage.saveImage(image: data, name: "doc_front") else {
            onError(error: SmileIDError.unknown("Error saving front document image"))
            return
        }
        documentFrontFile = file
        DispatchQueue.main.async {
            self.step = .backDocumentCapture
        }
    }

    func onBackDocumentImageConfirmed(data: Data) {
        guard let file = try? LocalStorage.saveImage(image: data, name: "doc_back") else {
            onError(error: SmileIDError.unknown("Error saving back document image"))
            return
        }
        documentBackFile = file
        DispatchQueue.main.async {
            self.step = .selfieCapture
        }
    }

    func onError(error: Error) {
        stepToRetry = step
        DispatchQueue.main.async {
            self.step = .processing(.error)
        }
    }

    func onFinished(delegate: DocumentCaptureResultDelegate) {
        if let jobStatusResponse = jobStatusResponse,
           let selfieFile = selfieFile,
           let documentFrontFile = documentFrontFile {
            delegate.didSucceed(
                selfie: selfieFile,
                documentFrontImage: documentFrontFile,
                documentBackImage: documentBackFile,
                jobStatusResponse: jobStatusResponse
            )
        } else {
            // TODO: Send actual error, if one was saved/exists
            delegate.didError(error: SmileIDError.unknown("Error getting job status response"))
        }
    }

    /// If stepToRetry is ProcessingScreen, we're retrying a network issue, so we need to kick off
    /// the resubmission manually. Otherwise, we're retrying a capture error, so we just need to
    /// reset the UI state
    func onRetry() {
        let step = stepToRetry
        stepToRetry = nil
        if let stepToRetry = step {
            DispatchQueue.main.async {
                self.step = stepToRetry
            }
            if case .processing = stepToRetry {
                submitJob()
            }
        }
    }

    func submitJob() {
        guard let documentFrontFile = documentFrontFile else {
            onError(error: SmileIDError.unknown("Error getting document front file"))
            return
        }
        DispatchQueue.main.async {
            self.step = .processing(.inProgress)
        }

        // TODO: Perform network request
    }

    // On Selfie Capture complete
    func didCapture(selfie: Data, livenessImages: [Data]) {
        do {
            let imageUrls = try LocalStorage.saveImageJpg(
                livenessImages: livenessImages,
                previewImage: selfie
            )
            selfieFile = imageUrls.selfie
            livenessFiles = imageUrls.livenessImages
            submitJob()
        } catch {
            print(error)
            onError(error: SmileIDError.unknown("Error saving image capture"))
        }
    }
}

struct OrchestratedDocumentVerificationScreen: View {
    let countryCode: String
    let documentType: String?
    let captureBothSides: Bool
    let idAspectRatio: Double?
    let bypassSelfieCaptureWithFile: URL?
    let userId: String
    let jobId: String
    let showAttribution: Bool
    let allowGalleryUpload: Bool
    let showInstructions: Bool
    let onResult: DocumentCaptureResultDelegate

    @ObservedObject private var viewModel: OrchestratedDocumentViewModel

    init(
        countryCode: String,
        documentType: String?,
        captureBothSides: Bool,
        idAspectRatio: Double?,
        bypassSelfieCaptureWithFile: URL?,
        userId: String,
        jobId: String,
        showAttribution: Bool,
        allowGalleryUpload: Bool,
        showInstructions: Bool,
        onResult: DocumentCaptureResultDelegate
    ) {
        self.countryCode = countryCode
        self.documentType = documentType
        self.captureBothSides = captureBothSides
        self.idAspectRatio = idAspectRatio
        self.bypassSelfieCaptureWithFile = bypassSelfieCaptureWithFile
        self.userId = userId
        self.jobId = jobId
        self.showAttribution = showAttribution
        self.allowGalleryUpload = allowGalleryUpload
        self.showInstructions = showInstructions
        self.onResult = onResult
        viewModel = OrchestratedDocumentViewModel(
            userId: userId,
            jobId: jobId,
            countryCode: countryCode,
            documentType: documentType,
            captureBothSides: captureBothSides,
            selfieFile: bypassSelfieCaptureWithFile
        )
    }

    var body: some View {
        switch viewModel.step {
        case .frontDocumentCapture:
            DocumentCaptureScreen(
                showInstructions: showInstructions,
                showAttribution: showAttribution,
                allowGallerySelection: allowGalleryUpload,
                showSkipButton: false,
                instructionsTitleText: SmileIDResourcesHelper.localizedString(
                    for: "Instructions.Document.Front.Header"
                ),
                instructionsSubtitleText: SmileIDResourcesHelper.localizedString(
                    for: "Instructions.Document.Front.Callout"
                ),
                captureTitleText: SmileIDResourcesHelper.localizedString(for: "Action.TakePhoto"),
                knownIdAspectRatio: idAspectRatio,
                onConfirm: viewModel.onFrontDocumentImageConfirmed,
                onError: viewModel.onError
            )
        case .backDocumentCapture:
            DocumentCaptureScreen(
                showInstructions: showInstructions,
                showAttribution: showAttribution,
                allowGallerySelection: allowGalleryUpload,
                showSkipButton: true,
                instructionsTitleText: SmileIDResourcesHelper.localizedString(
                    for: "Instructions.Document.Back.Header"
                ),
                instructionsSubtitleText: SmileIDResourcesHelper.localizedString(
                    for: "Instructions.Document.Back.Callout"
                ),
                captureTitleText: SmileIDResourcesHelper.localizedString(for: "Action.TakePhoto"),
                knownIdAspectRatio: idAspectRatio,
                onConfirm: viewModel.onBackDocumentImageConfirmed,
                onError: viewModel.onError
            )
        case .selfieCapture:
            SelfieCaptureView(
                viewModel: SelfieCaptureViewModel(
                    userId: userId,
                    jobId: jobId,
                    isEnroll: false,
                    shouldSubmitJob: false,
                    // imageCaptureDelegate is just for image capture, not job result
                    imageCaptureDelegate: viewModel
                ),
                delegate: SelfiePlaceHolderDelegate()
            )
        case .processing(let state):
            ProcessingScreen(
                processingState: state,
                inProgressTitle: SmileIDResourcesHelper.localizedString(
                    for: "Document.Processing.Header"
                ),
                inProgressSubtitle: SmileIDResourcesHelper.localizedString(
                    for: "Document.Processing.Callout"
                ),
                inProgressIcon: SmileIDResourcesHelper.Scan,
                successTitle: SmileIDResourcesHelper.localizedString(
                    for: "Document.Complete.Header"
                ),
                successSubtitle: SmileIDResourcesHelper.localizedString(
                    for: "Document.Complete.Callout"
                ),
                successIcon: SmileIDResourcesHelper.CheckBold,
                errorTitle: SmileIDResourcesHelper.localizedString(for: "Document.Error.Header"),
                errorSubtitle: SmileIDResourcesHelper.localizedString(
                    for: "Confirmation.FailureReason"
                ),
                // TODO: Replace this with the actual error icon
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
