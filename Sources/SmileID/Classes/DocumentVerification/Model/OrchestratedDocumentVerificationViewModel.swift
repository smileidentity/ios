import Combine
import SwiftUI

enum DocumentCaptureFlow: Equatable {
    case frontDocumentCapture
    case backDocumentCapture
    case selfieCapture
    case processing(ProcessingState)
}

internal class IOrchestratedDocumentVerificationViewModel<T, U: JobResult>: ObservableObject {
    // Input properties
    internal let userId: String
    internal let jobId: String
    internal let allowNewEnroll: Bool
    internal let countryCode: String
    internal let documentType: String?
    internal let captureBothSides: Bool
    internal var selfieFile: Data?
    internal let jobType: JobType
    internal let extraPartnerParams: [String: String]

    // Other properties
    internal var documentFrontFile: Data?
    internal var documentBackFile: Data?
    internal var livenessFiles: [Data]?
    internal var jobStatusResponse: JobStatusResponse<U>?
    internal var savedFiles: DocumentCaptureResultStore?
    internal var networkingSubscriber: AnyCancellable?
    internal var stepToRetry: DocumentCaptureFlow?
    internal var error: Error?

    // UI properties
    @Published var acknowledgedInstructions = false
    @Published var step = DocumentCaptureFlow.frontDocumentCapture

    internal init(
        userId: String,
        jobId: String,
        allowNewEnroll: Bool,
        countryCode: String,
        documentType: String?,
        captureBothSides: Bool,
        selfieFile: URL?,
        jobType: JobType,
        extraPartnerParams: [String: String] = [:]
    ) {
        self.userId = userId
        self.jobId = jobId
        self.allowNewEnroll = allowNewEnroll
        self.countryCode = countryCode
        self.documentType = documentType
        self.captureBothSides = captureBothSides
        self.selfieFile = selfieFile.flatMap { try? Data(contentsOf: $0) }
        self.jobType = jobType
        self.extraPartnerParams = extraPartnerParams
    }

    func onFrontDocumentImageConfirmed(data: Data) {
        documentFrontFile = data
        if captureBothSides {
            DispatchQueue.main.async {
                self.step = .backDocumentCapture
            }
        } else {
            DispatchQueue.main.async {
                self.step = .selfieCapture
            }
        }
    }

    func onBackDocumentImageConfirmed(data: Data) {
        documentBackFile = data
        DispatchQueue.main.async {
            self.step = .selfieCapture
        }
    }

    func acknowledgeInstructions() {
        self.acknowledgedInstructions = true
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

    func onFinished(delegate: T) {
        fatalError("Must override onFinished")
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
        networkingSubscriber = auth.flatMap { [self] authResponse in
                let prepUploadRequest = PrepUploadRequest(
                    partnerParams: authResponse.partnerParams.copy(extras: self.extraPartnerParams),
                    allowNewEnroll: String(allowNewEnroll), // TODO - Fix when Michael changes this to boolean
                    timestamp: authResponse.timestamp,
                    signature: authResponse.signature
                )
                return SmileID.api.prepUpload(request: prepUploadRequest)
            }
            .flatMap { prepUploadResponse in
                SmileID.api.upload(zip: zip, to: prepUploadResponse.uploadUrl)
            }
            .zip(auth)
            .flatMap { _, authResponse -> AnyPublisher<JobStatusResponse<U>, Error> in
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
}

extension IOrchestratedDocumentVerificationViewModel: SmartSelfieResultDelegate {
    func didSucceed(selfieImage: URL, livenessImages: [URL], jobStatusResponse: SmartSelfieJobStatusResponse?) {
        selfieFile = try? Data(contentsOf: selfieImage)
        livenessFiles = livenessImages.compactMap { try? Data(contentsOf: $0) }
        submitJob()
    }

    func didError(error: Error) {
        onError(error: SmileIDError.unknown("Error capturing selfie"))
    }
}

internal class OrchestratedDocumentVerificationViewModel:
    IOrchestratedDocumentVerificationViewModel<DocumentVerificationResultDelegate, DocumentVerificationJobResult> {
    override func onFinished(delegate: DocumentVerificationResultDelegate) {
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
}

internal class OrchestratedEnhancedDocumentVerificationViewModel:
    IOrchestratedDocumentVerificationViewModel<EnhancedDocumentVerificationResultDelegate, EnhancedDocumentVerificationJobResult> {
    override func onFinished(delegate: EnhancedDocumentVerificationResultDelegate) {
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
}
