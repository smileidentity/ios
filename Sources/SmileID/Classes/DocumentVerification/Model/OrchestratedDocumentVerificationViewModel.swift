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
    internal let jobType: JobType
    internal let extraPartnerParams: [String: String]

    // Other properties
    internal var documentFrontFile: Data?
    internal var documentBackFile: Data?
    internal var selfieFile: URL?
    internal var livenessFiles: [URL]?
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
        self.selfieFile = selfieFile
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
            var allFiles = [URL]()
            let frontDocumentUrl = try LocalStorage.createDocumentFile(jobId: jobId, document: documentFrontFile)
            allFiles.append(frontDocumentUrl)
            var backDocumentUrl: URL?
            if let documentBackFile = documentBackFile {
                let url = try LocalStorage.createDocumentFile(jobId: jobId, document: documentBackFile)
                backDocumentUrl = url
                allFiles.append(url)
            }
            allFiles.append(selfieFile)
            var livenessImagesUrl = [URL]()
            if let livenessFiles = livenessFiles {
                allFiles.append(contentsOf: livenessFiles)
            }
            let info = try LocalStorage.createInfoJsonFile(
                jobId: jobId,
                idInfo: IdInfo(country: countryCode),
                documentFront: frontDocumentUrl,
                documentBack: backDocumentUrl,
                selfie: selfieFile,
                livenessImages: livenessImagesUrl
            )
            allFiles.append(info)
            let zipUrl = try LocalStorage.zipFiles(at: allFiles)
            zip = try Data(contentsOf: zipUrl)
            self.savedFiles = DocumentCaptureResultStore(
                allFiles: allFiles,
                documentFront: frontDocumentUrl,
                documentBack: backDocumentUrl,
                selfie: selfieFile,
                livenessImages: livenessImagesUrl
            )
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
                            do {
                                _ = try LocalStorage.saveOfflineJob(
                                    jobId: self.jobId,
                                    userId: self.userId,
                                    jobType: self.jobType,
                                    enrollment: false,
                                    allowNewEnroll: self.allowNewEnroll,
                                    partnerParams: self.extraPartnerParams
                                )
                            } catch {
                                print("Error submitting job: \(error)")
                                self.onError(error: SmileIDError.unknown("Failed to create file"))
                            }
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
        selfieFile = selfieImage
        livenessFiles = livenessImages
        submitJob()
    }

    func didError(error: Error) {
        onError(error: SmileIDError.unknown("Error capturing selfie"))
    }
}

// swiftlint:disable colon
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

// swiftlint:disable colon
internal class OrchestratedEnhancedDocumentVerificationViewModel:
    // swiftlint:disable line_length
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
