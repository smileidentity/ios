import Combine
import SwiftUI

enum DocumentCaptureFlow: Equatable {
    case frontDocumentCapture
    case backDocumentCapture
    case selfieCapture
    case processing(ProcessingState)
}

class IOrchestratedDocumentVerificationViewModel<T, U: JobResult>: ObservableObject {
    // Input properties
    let userId: String
    let jobId: String
    let consentInformation: ConsentInformation?
    let allowNewEnroll: Bool
    let countryCode: String
    let documentType: String?
    let captureBothSides: Bool
    let skipApiSubmission: Bool
    let useStrictMode: Bool
    let jobType: JobType
    let extraPartnerParams: [String: String]

    // Other properties
    var documentFrontFile: Data?
    var documentBackFile: Data?
    var selfieFile: URL?
    var livenessFiles: [URL]?
    var savedFiles: DocumentCaptureResultStore?
    var stepToRetry: DocumentCaptureFlow?
    var didSubmitJob: Bool = false
    var error: Error?
    let metadata: Metadata = .shared
    private var networkRetries: Int = 0

    // UI properties
    @Published var acknowledgedInstructions = false
    /// we use `errorMessageRes` to map to the actual code to the stringRes to allow localization,
    /// and use `errorMessage` to show the actual platform error message that we show if
    /// `errorMessageRes` is not set by the partner
    @Published var errorMessageRes: String?
    @Published var errorMessage: String?
    @Published var step = DocumentCaptureFlow.frontDocumentCapture

    init(
        userId: String,
        jobId: String,
        consentInformation: ConsentInformation?,
        allowNewEnroll: Bool,
        countryCode: String,
        documentType: String?,
        captureBothSides: Bool,
        skipApiSubmission: Bool,
        useStrictMode: Bool,
        selfieFile: URL?,
        jobType: JobType,
        extraPartnerParams: [String: String] = [:]
    ) {
        self.userId = userId
        self.jobId = jobId
        self.consentInformation = consentInformation
        self.allowNewEnroll = allowNewEnroll
        self.countryCode = countryCode
        self.documentType = documentType
        self.captureBothSides = captureBothSides
        self.skipApiSubmission = skipApiSubmission
        self.useStrictMode = useStrictMode
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
                    jobId: useStrictMode ? userId : jobId,
                    fileType: FileType.selfie
                )

                livenessFiles = try LocalStorage.getFilesByType(
                    jobId: useStrictMode ? userId : jobId,
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
                    jobId: jobId,
                    fileType: FileType.documentFront,
                    document: documentFrontFile
                )
                allFiles.append(contentsOf: [selfieFile, frontDocumentUrl])
                var backDocumentUrl: URL?
                if let documentBackFile {
                    let url = try LocalStorage.createDocumentFile(
                        jobId: jobId,
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
                    jobId: jobId,
                    idInfo: IdInfo(country: countryCode, idType: documentType),
                    consentInformation: consentInformation,
                    documentFront: frontDocumentUrl,
                    documentBack: backDocumentUrl,
                    selfie: selfieFile,
                    livenessImages: livenessFiles
                )
                allFiles.append(info)
                let zipData: Data
                let securityInfo = try? createSecurityInfo(files: allFiles)
                if let securityInfo = securityInfo {
                    zipData = try LocalStorage.zipFiles(
                        urls: allFiles,
                        data: ["security_info.json": securityInfo]
                    )
                } else {
                    /*
                     In case we can't add the security info the backend will throw an unauthorized error.
                     In the future, we will handle this more gracefully once sentry integration has been implemented.
                     */
                    zipData = try LocalStorage.zipFiles(urls: allFiles)
                }
                self.savedFiles = DocumentCaptureResultStore(
                    allFiles: allFiles,
                    documentFront: frontDocumentUrl,
                    documentBack: backDocumentUrl,
                    selfie: selfieFile,
                    livenessImages: livenessFiles ?? []
                )
                if skipApiSubmission {
                    DispatchQueue.main.async { self.step = .processing(.success) }
                    return
                }
                let authRequest = AuthenticationRequest(
                    jobType: jobType,
                    enrollment: false,
                    jobId: jobId,
                    userId: userId
                )
                let metadata = metadata.collectAllMetadata()
                if SmileID.allowOfflineMode {
                    try LocalStorage.saveOfflineJob(
                        jobId: jobId,
                        userId: userId,
                        jobType: jobType,
                        enrollment: false,
                        allowNewEnroll: allowNewEnroll,
                        metadata: metadata,
                        partnerParams: extraPartnerParams
                    )
                }
                let authResponse = try await SmileID.api.authenticate(request: authRequest)
                var prepUploadRequest = PrepUploadRequest(
                    partnerParams: authResponse.partnerParams.copy(extras: self.extraPartnerParams),
                    allowNewEnroll: allowNewEnroll,
                    metadata: metadata,
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
                        incrementNetworkRetries()
                        prepUploadRequest.retry = true
                        prepUploadResponse = try await SmileID.api.prepUpload(
                            request: prepUploadRequest
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
                    try LocalStorage.moveToSubmittedJobs(jobId: self.jobId)
                    if useStrictMode {
                        try LocalStorage.moveToSubmittedJobs(jobId: self.userId)
                    }
                    self.selfieFile =
                        try LocalStorage.getFileByType(
                            jobId: useStrictMode ? userId : jobId,
                            fileType: FileType.selfie,
                            submitted: true
                        ) ?? selfieFile
                    self.livenessFiles =
                        try LocalStorage.getFilesByType(
                            jobId: useStrictMode ? userId : jobId,
                            fileType: FileType.liveness,
                            submitted: true
                        ) ?? []
                } catch {
                    print("Error moving job to submitted directory: \(error)")
                    self.onError(error: error)
                    return
                }
                resetNetworkRetries()
                DispatchQueue.main.async { self.step = .processing(.success) }
            } catch let error as SmileIDError {
                do {
                    var didMove = try LocalStorage.handleOfflineJobFailure(
                        jobId: self.jobId,
                        error: error
                    )

                    if useStrictMode {
                        didMove = try LocalStorage.handleOfflineJobFailure(
                            jobId: self.userId,
                            error: error
                        )
                    }

                    if didMove {
                        self.selfieFile =
                            try LocalStorage.getFileByType(
                                jobId: useStrictMode ? userId : jobId,
                                fileType: FileType.selfie,
                                submitted: true
                            ) ?? selfieFile
                        self.livenessFiles =
                            try LocalStorage.getFilesByType(
                                jobId: useStrictMode ? userId : jobId,
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
                incrementNetworkRetries()
                submitJob()
            }
        }
    }
}

// MARK: - Metadata Helpers
extension IOrchestratedDocumentVerificationViewModel {
    private func incrementNetworkRetries() {
        networkRetries += 1
        Metadata.shared.addMetadata(key: .networkRetries, value: networkRetries)
    }

    func resetNetworkRetries() {
        networkRetries = 0
        Metadata.shared.removeMetadata(key: .networkRetries)
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
}

// swiftlint:disable opening_brace
class OrchestratedDocumentVerificationViewModel: IOrchestratedDocumentVerificationViewModel<DocumentVerificationResultDelegate, DocumentVerificationJobResult> {
    override func onFinished(delegate: DocumentVerificationResultDelegate) {
        if let error {
            delegate.didError(error: error)
        } else if let savedFiles, let selfieFile {
            delegate.didSucceed(
                selfie: selfieFile,
                documentFrontImage: savedFiles.documentFront,
                documentBackImage: savedFiles.documentBack,
                didSubmitDocumentVerificationJob: didSubmitJob
            )
        } else {
            delegate.didError(error: SmileIDError.unknown("Unknown error"))
        }
    }
}

// swiftlint:disable opening_brace
class OrchestratedEnhancedDocumentVerificationViewModel: IOrchestratedDocumentVerificationViewModel<EnhancedDocumentVerificationResultDelegate, EnhancedDocumentVerificationJobResult> {
    override func onFinished(delegate: EnhancedDocumentVerificationResultDelegate) {
        if let error {
            delegate.didError(error: error)
        } else if let savedFiles, let selfieFile {
            delegate.didSucceed(
                selfie: selfieFile,
                documentFrontImage: savedFiles.documentFront,
                documentBackImage: savedFiles.documentBack,
                didSubmitEnhancedDocVJob: didSubmitJob
            )
        } else {
            delegate.didError(error: SmileIDError.unknown("Unknown error"))
        }
    }
}
