import Combine
import Foundation

class IOrchestratedDocumentVerificationViewModel<T, U: JobResult>: ObservableObject {
    // Input properties
    let config: DocumentVerificationConfig
    let jobType: JobType

    // Other properties
    var documentFrontFile: Data?
    var documentBackFile: Data?
    var selfieFile: URL?
    var livenessFiles: [URL]?
    var savedFiles: DocumentCaptureResultStore?
    var stepToRetry: DocumentCaptureFlow?
    var didSubmitJob: Bool = false
    var error: Error?
    var localMetadata: LocalMetadata

    // UI properties
    @Published var acknowledgedInstructions = false
    /// we use `errorMessageRes` to map to the actual code to the stringRes to allow localization,
    /// and use `errorMessage` to show the actual platform error message that we show if
    /// `errorMessageRes` is not set by the partner
    @Published var errorMessageRes: String?
    @Published var errorMessage: String?
    @Published var step = DocumentCaptureFlow.frontDocumentCapture

    init(
        config: DocumentVerificationConfig,
        jobType: JobType,
        localMetadata: LocalMetadata
    ) {
        self.config = config
        self.jobType = jobType
        self.localMetadata = localMetadata
    }

    func onFrontDocumentImageConfirmed(data: Data) {
        documentFrontFile = data
        if config.captureBothSides {
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
        acknowledgedInstructions = true
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

    func onFinished(delegate _: T) {
        fatalError("Must override onFinished")
    }

    func submitJob() {
        Task {
            do {
                guard let documentFrontFile else {
                    // Set step to .frontDocumentCapture so that the Retry button goes back to this step
                    step = .frontDocumentCapture
                    onError(error: SmileIDError.unknown("Error getting document front file"))
                    return
                }

                selfieFile = try LocalStorage.getFileByType(
                    jobId: config.useStrictMode ? config.userId : config.jobId,
                    fileType: FileType.selfie
                )

                livenessFiles = try LocalStorage.getFilesByType(
                    jobId: config.useStrictMode ? config.userId : config.jobId,
                    fileType: FileType.liveness
                )

                guard let selfieFile else {
                    // Set step to .selfieCapture so that the Retry button goes back to this step
                    step = .selfieCapture
                    onError(error: SmileIDError.unknown("Error getting selfie file"))
                    return
                }

                DispatchQueue.main.async {
                    self.step = .processing(.inProgress)
                }

                var allFiles = [URL]()
                let frontDocumentUrl = try LocalStorage.createDocumentFile(
                    jobId: config.jobId,
                    fileType: FileType.documentFront,
                    document: documentFrontFile
                )
                allFiles.append(contentsOf: [selfieFile, frontDocumentUrl])
                var backDocumentUrl: URL?
                if let documentBackFile {
                    let url = try LocalStorage.createDocumentFile(
                        jobId: config.jobId,
                        fileType: FileType.documentBack,
                        document: documentBackFile
                    )
                    backDocumentUrl = url
                    allFiles.append(url)
                }
                if let livenessFiles {
                    allFiles.append(contentsOf: livenessFiles)
                }
                let info = try LocalStorage.createInfoJsonFile(
                    jobId: config.jobId,
                    idInfo: IdInfo(country: config.countryCode, idType: config.documentType),
                    consentInformation: config.consentInformation,
                    documentFront: frontDocumentUrl,
                    documentBack: backDocumentUrl,
                    selfie: selfieFile,
                    livenessImages: livenessFiles
                )
                allFiles.append(info)
                let zipData = try LocalStorage.zipFiles(at: allFiles)
                self.savedFiles = DocumentCaptureResultStore(
                    allFiles: allFiles,
                    documentFront: frontDocumentUrl,
                    documentBack: backDocumentUrl,
                    selfie: selfieFile,
                    livenessImages: livenessFiles ?? []
                )
                if config.skipApiSubmission {
                    DispatchQueue.main.async { self.step = .processing(.success) }
                    return
                }
                let authRequest = AuthenticationRequest(
                    jobType: self.jobType,
                    enrollment: false,
                    jobId: self.config.jobId,
                    userId: self.config.userId
                )
                if SmileID.allowOfflineMode {
                    try LocalStorage.saveOfflineJob(
                        jobId: self.config.jobId,
                        userId: self.config.userId,
                        jobType: self.jobType,
                        enrollment: false,
                        allowNewEnroll: self.config.allowNewEnroll,
                        localMetadata: localMetadata,
                        partnerParams: self.config.extraPartnerParams
                    )
                }
                let authResponse = try await SmileID.api.authenticate(request: authRequest)
                let prepUploadRequest = PrepUploadRequest(
                    partnerParams: authResponse.partnerParams.copy(
                        extras: self.config.extraPartnerParams),
                    // TODO: - Fix when Michael changes this to boolean
                    allowNewEnroll: String(self.config.allowNewEnroll),
                    metadata: self.localMetadata.metadata.items,
                    timestamp: authResponse.timestamp,
                    signature: authResponse.signature
                )
                let prepUploadResponse: PrepUploadResponse
                do {
                    prepUploadResponse = try await SmileID.api.prepUpload(
                        request: prepUploadRequest
                    )
                } catch let error as SmileIDError {
                    switch error {
                    case .api("2215", _):
                        prepUploadResponse = try await SmileID.api.prepUpload(
                            request: prepUploadRequest.copy(retry: "true")
                        )
                    default:
                        throw error
                    }
                }
                let _ = try await SmileID.api.upload(
                    zip: zipData,
                    to: prepUploadResponse.uploadUrl
                )
                didSubmitJob = true
                do {
                    try LocalStorage.moveToSubmittedJobs(jobId: self.config.jobId)
                    if config.useStrictMode {
                        try LocalStorage.moveToSubmittedJobs(jobId: self.config.userId)
                    }
                    self.selfieFile =
                        try LocalStorage.getFileByType(
                            jobId: self.config.useStrictMode
                                ? self.config.userId : self.config.jobId,
                            fileType: FileType.selfie,
                            submitted: true
                        ) ?? selfieFile
                    self.livenessFiles =
                        try LocalStorage.getFilesByType(
                            jobId: self.config.useStrictMode
                                ? self.config.userId : self.config.jobId,
                            fileType: FileType.liveness,
                            submitted: true
                        ) ?? []
                } catch {
                    print("Error moving job to submitted directory: \(error)")
                    self.onError(error: error)
                    return
                }
                DispatchQueue.main.async { self.step = .processing(.success) }
            } catch let error as SmileIDError {
                do {
                    var didMove = try LocalStorage.handleOfflineJobFailure(
                        jobId: self.config.jobId,
                        error: error
                    )

                    if config.useStrictMode {
                        didMove = try LocalStorage.handleOfflineJobFailure(
                            jobId: self.config.userId,
                            error: error
                        )
                    }

                    if didMove {
                        self.selfieFile =
                            try LocalStorage.getFileByType(
                                jobId: self.config.useStrictMode
                                    ? self.config.userId : self.config.jobId,
                                fileType: FileType.selfie,
                                submitted: true
                            ) ?? selfieFile
                        self.livenessFiles =
                            try LocalStorage.getFilesByType(
                                jobId: self.config.useStrictMode
                                    ? self.config.userId : self.config.jobId,
                                fileType: FileType.liveness,
                                submitted: true
                            ) ?? []
                    }
                } catch {
                    print("Error moving job to submitted directory: \(error)")
                    self.onError(error: error)
                    return
                }
                if SmileID.allowOfflineMode, SmileIDError.isNetworkFailure(error: error) {
                    didSubmitJob = true
                    DispatchQueue.main.async {
                        self.errorMessageRes = "Offline.Message"
                        self.step = .processing(.success)
                    }
                } else {
                    didSubmitJob = false
                    print("Error submitting job: \(error)")
                    self.onError(error: error)
                    let (errorMessageRes, errorMessage) = toErrorMessage(error: error)
                    self.errorMessageRes = errorMessageRes
                    self.errorMessage = errorMessage
                }
            } catch {
                didSubmitJob = false
                print("Error submitting job: \(error)")
                self.onError(error: error)
            }
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
}

extension IOrchestratedDocumentVerificationViewModel: SmartSelfieResultDelegate {
    func didSucceed(
        selfieImage _: URL,
        livenessImages _: [URL],
        apiResponse _: SmartSelfieResponse?
    ) {
        submitJob()
    }

    func didError(error: Error) {
        onError(error: SmileIDError.unknown("Error capturing selfie"))
    }

    func didCancel() {}
}

extension IOrchestratedDocumentVerificationViewModel: SelfieCaptureDelegate {
    func didFinish(with result: SelfieCaptureResult, failureReason: FailureReason?) {
        submitJob()
    }

    func didFinish(with error: any Error) {
        onError(error: SmileIDError.selfieCaptureFailed)
    }
}
