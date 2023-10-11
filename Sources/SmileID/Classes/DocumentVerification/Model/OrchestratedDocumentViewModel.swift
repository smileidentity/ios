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

    func onDocumentBackSkip() {
        if selfieFile == nil {
            DispatchQueue.main.async {
                self.step = .selfieCapture
            }
        } else {
            submitJob()
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
