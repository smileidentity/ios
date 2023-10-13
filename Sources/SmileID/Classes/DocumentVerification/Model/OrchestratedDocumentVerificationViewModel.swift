import Combine
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

class OrchestratedDocumentVerificationViewModel<T>: ObservableObject, SelfieImageCaptureDelegate {
    // Input properties
    private let userId: String
    private let jobId: String
    private let countryCode: String
    private let documentType: String?
    private let captureBothSides: Bool
    private var selfieFile: Data?
    private let jobType: JobType

    // Other properties
    private var documentFrontFile: Data?
    private var documentBackFile: Data?
    private var livenessFiles: [Data]?
    private var jobStatusResponse: JobStatusResponse?
    private var savedFiles: DocumentCaptureResultStore?
    private var networkingSubscriber: AnyCancellable?
    private var stepToRetry: DocumentCaptureFlow?
    private var error: Error?

    // UI properties
    @Published var step = DocumentCaptureFlow.frontDocumentCapture

    init(
        userId: String,
        jobId: String,
        countryCode: String,
        documentType: String?,
        captureBothSides: Bool,
        selfieFile: URL?,
        jobType: JobType = .documentVerification
    ) {
        self.userId = userId
        self.jobId = jobId
        self.countryCode = countryCode
        self.documentType = documentType
        self.captureBothSides = captureBothSides
        self.selfieFile = selfieFile.flatMap { try? Data(contentsOf: $0) }
        if jobType != .documentVerification && jobType != .enhancedDocumentVerification {
            fatalError("jobType must be documentVerification or enhancedDocumentVerification")
        }
        self.jobType = jobType
    }

    func onFrontDocumentImageConfirmed(data: Data) {
        documentFrontFile = data
        DispatchQueue.main.async {
            self.step = .backDocumentCapture
        }
    }

    func onBackDocumentImageConfirmed(data: Data) {
        documentBackFile = data
        DispatchQueue.main.async {
            self.step = .selfieCapture
        }
    }

    func onError(error: Error) {
        self.error = error
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

    /// On Selfie Capture complete
    func didCapture(selfie: Data, livenessImages: [Data]) {
        selfieFile = selfie
        livenessFiles = livenessImages
        submitJob()
    }

    func onFinished(delegate: DocumentVerificationResultDelegate) {
        if let jobStatusResponse = jobStatusResponse, let savedFiles = savedFiles {
            delegate.didSucceed(
                selfie: savedFiles.selfie,
                documentFrontImage: savedFiles.documentFront,
                documentBackImage: savedFiles.documentBack,
                jobStatusResponse: jobStatusResponse
            )
        } else if let error = error {
            // We check error as the 2nd case because as long as jobStatusResponse is not nil, it
            // was a success
            delegate.didError(error: error)
        } else {
            delegate.didError(error: SmileIDError.unknown("Unknown error"))
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
            // Set step to .frontDocumentCapture so that the Retry button goes back to this step
            step = .frontDocumentCapture
            onError(error: SmileIDError.unknown("Error getting document front file"))
            return
        }
        guard let selfieFile = selfieFile else {
            // Set step to .selfieCapture so that the Retry button goes back to this step
            step = .selfieCapture
            onError(error: SmileIDError.unknown("Error getting selfie file"))
            return
        }
        DispatchQueue.main.async {
            self.step = .processing(.inProgress)
        }

        let zip: Data
        do {
            let savedFiles = try LocalStorage.saveDocumentImages(
                front: documentFrontFile,
                back: documentBackFile,
                selfie: selfieFile,
                livenessImages: livenessFiles,
                countryCode: countryCode,
                documentType: documentType
            )
            let zipUrl = try LocalStorage.zipFiles(at: savedFiles.allFiles)
            zip = try Data(contentsOf: zipUrl)
            self.savedFiles = savedFiles
        } catch {
            print("Error saving document images: \(error)")
            onError(error: SmileIDError.unknown("Error saving document images"))
            return
        }

        let authRequest = AuthenticationRequest(
            jobType: jobType,
            enrollment: false,
            jobId: jobId,
            userId: userId
        )

        let auth = SmileID.api.authenticate(request: authRequest)
        networkingSubscriber = auth.flatMap { authResponse in
                let prepUploadRequest = PrepUploadRequest(
                    partnerParams: authResponse.partnerParams,
                    timestamp: authResponse.timestamp,
                    signature: authResponse.signature
                )
                return SmileID.api.prepUpload(request: prepUploadRequest)
            }
            .flatMap { prepUploadResponse in
                SmileID.api.upload(zip: zip, to: prepUploadResponse.uploadUrl)
            }
            .zip(auth)
            .flatMap { uploadResponse, authResponse in
                let jobStatusRequest = JobStatusRequest(
                    userId: authResponse.partnerParams.userId,
                    jobId: authResponse.partnerParams.jobId,
                    includeImageLinks: false,
                    includeHistory: false,
                    timestamp: authResponse.timestamp,
                    signature: authResponse.signature
                )
                return SmileID.api.getJobStatus(request: jobStatusRequest)
            }
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        print("Error submitting job: \(error)")
                        self.onError(error: SmileIDError.unknown("Network error"))
                    default:
                        break
                    }
                },
                receiveValue: { response in
                    self.jobStatusResponse = response
                    DispatchQueue.main.async {
                        self.step = .processing(.success)
                    }
                }
            )
    }
}