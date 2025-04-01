import Combine
import Foundation

class OrchestratedBiometricKycViewModel: ObservableObject {
    // MARK: - Input Properties

    private let config: BiometricVerificationConfig
    private let localMetadata = LocalMetadata()

    weak var delegate: BiometricKycResultDelegate?

    // MARK: - Other Properties

    var selfieFile: URL?
    var livenessFiles: [URL]?
    private var error: Error?
    private var didSubmitBiometricJob: Bool = false

    // MARK: - UI Properties

    /// we use `errorMessageRes` to map to the actual code to the stringRes to allow localization,
    /// and use `errorMessage` to show the actual platform error message that we show if
    /// `errorMessageRes` is not set by the partner
    @Published var errorMessageRes: String?
    @Published var errorMessage: String?
    @Published var processingState: ProcessingState?

    init(
        config: BiometricVerificationConfig,
        delegate: BiometricKycResultDelegate
    ) {
        self.config = config
        self.delegate = delegate
    }

    func onRetry() {
        if selfieFile != nil {
            submitJob()
        } else {
            updateProcessingState(nil)
        }
    }

    func handleContinue() {
        onFinished()
    }

    func handleClose() {
        onFinished()
    }

    func handleCancel() {
        delegate?.didCancel()
    }

    private func onFinished() {
        if let selfieFile = selfieFile,
           let livenessFiles = livenessFiles,
           let selfiePath = getRelativePath(from: selfieFile) {
            delegate?.didSucceed(
                selfieImage: selfiePath,
                livenessImages: livenessFiles.compactMap { getRelativePath(from: $0) },
                didSubmitBiometricJob: didSubmitBiometricJob
            )
        } else if let error {
            delegate?.didError(error: error)
        }
    }

    func submitJob() {
        updateProcessingState(.inProgress)
        Task {
            do {
                try await handleJobSubmission()
                updateProcessingState(.success)
            } catch let error as SmileIDError {
                handleSubmissionFailure(error)
            } catch {
                didSubmitBiometricJob = false
                print("Error submitting job: \(error)")
                self.error = error
                updateProcessingState(.error)
            }
        }
    }
}

// Job Submission Helpers
extension OrchestratedBiometricKycViewModel {
    private func handleJobSubmission() async throws {
        try fetchRequiredFiles()

        let zipData = try createZipData()

        let authResponse = try await authenticate()

        let preUploadResponse = try await prepareForUpload(authResponse: authResponse)

        try await uploadFiles(zipData: zipData, uploadUrl: preUploadResponse.uploadUrl)
        didSubmitBiometricJob = true

        try moveJobToSubmittedDirectory()
    }

    private func fetchRequiredFiles() throws {
        selfieFile = try LocalStorage.getFileByType(
            jobId: config.useStrictMode ? config.userId : config.jobId,
            fileType: FileType.selfie
        )

        livenessFiles = try LocalStorage.getFilesByType(
            jobId: config.useStrictMode ? config.userId : config.jobId,
            fileType: FileType.liveness
        )

        guard selfieFile != nil else {
            // Set step to .selfieCapture so that the Retry button goes back to this step
            updateProcessingState(nil)
            error = SmileIDError.unknown("Error capturing selfie")
            return
        }
    }

    private func createZipData() throws -> Data {
        var allFiles = [URL]()
        let infoJson = try LocalStorage.createInfoJsonFile(
            jobId: config.jobId,
            idInfo: config.idInfo.copy(entered: true),
            consentInformation: config.consentInformation,
            selfie: selfieFile,
            livenessImages: livenessFiles
        )
        if let selfieFile {
            allFiles.append(contentsOf: [selfieFile, infoJson])
        }
        if let livenessFiles {
            allFiles.append(contentsOf: livenessFiles)
        }
        return try LocalStorage.zipFiles(at: allFiles)
    }

    private func authenticate() async throws -> AuthenticationResponse {
        let authRequest = AuthenticationRequest(
            jobType: .biometricKyc,
            enrollment: false,
            jobId: config.jobId,
            userId: config.userId,
            country: config.idInfo.country,
            idType: config.idInfo.idType
        )

        if SmileID.allowOfflineMode {
            try saveOfflineJobIfAllowed()
        }

        return try await SmileID.api.authenticate(request: authRequest)
    }

    private func saveOfflineJobIfAllowed() throws {
        try LocalStorage.saveOfflineJob(
            jobId: config.jobId,
            userId: config.userId,
            jobType: .biometricKyc,
            enrollment: false,
            allowNewEnroll: config.allowNewEnroll,
            localMetadata: localMetadata,
            partnerParams: config.extraPartnerParams
        )
    }

    private func prepareForUpload(authResponse: AuthenticationResponse) async throws -> PrepUploadResponse {
        let prepUploadRequest = PrepUploadRequest(
            partnerParams: authResponse.partnerParams.copy(extras: config.extraPartnerParams),
            allowNewEnroll: String(config.allowNewEnroll), // TODO: - Fix when Michael changes this to boolean
            metadata: localMetadata.metadata.items,
            timestamp: authResponse.timestamp,
            signature: authResponse.signature
        )
        do {
            return try await SmileID.api.prepUpload(
                request: prepUploadRequest
            )
        } catch let error as SmileIDError {
            guard case let .api(errorCode, _) = error,
                  errorCode == "2215"
            else {
                throw error
            }
            return try await SmileID.api.prepUpload(
                request: prepUploadRequest.copy(retry: "true"))
        }
    }

    private func uploadFiles(zipData: Data, uploadUrl: String) async throws {
        try await SmileID.api.upload(
            zip: zipData,
            to: uploadUrl
        )
    }

    private func moveJobToSubmittedDirectory() throws {
        try LocalStorage.moveToSubmittedJobs(jobId: config.jobId)
        if config.useStrictMode {
            try LocalStorage.moveToSubmittedJobs(jobId: config.userId)
        }
    }

    private func updateProcessingState(_ newState: ProcessingState?) {
        DispatchQueue.main.async {
            self.processingState = newState
        }
    }

    private func updateErrorMessages(
        errorMessage: String? = nil,
        errorMessageRes: String? = nil
    ) {
        DispatchQueue.main.async {
            self.errorMessage = errorMessage
            self.errorMessageRes = errorMessageRes
        }
    }

    private func handleSubmissionFailure(_ smileIDError: SmileIDError) {
        do {
            _ = try LocalStorage.handleOfflineJobFailure(
                jobId: config.jobId,
                error: smileIDError
            )
            if config.useStrictMode {
                _ = try LocalStorage.handleOfflineJobFailure(
                    jobId: config.userId,
                    error: smileIDError
                )
            }
        } catch {
            print("Error moving job to submitted directory: \(error)")
            self.error = smileIDError
            return
        }

        if SmileID.allowOfflineMode, SmileIDError.isNetworkFailure(error: smileIDError) {
            didSubmitBiometricJob = true
            updateErrorMessages(errorMessageRes: "Offline.Message")
            updateProcessingState(.success)
        } else {
            didSubmitBiometricJob = false
            print("Error submitting job: \(smileIDError)")
            let (errorMessageRes, errorMessage) = toErrorMessage(error: smileIDError)
            error = smileIDError
            updateErrorMessages(errorMessage: errorMessage, errorMessageRes: errorMessageRes)
            updateProcessingState(.error)
        }
    }
}

extension OrchestratedBiometricKycViewModel: SelfieCaptureDelegate {
    func didFinish(with result: SelfieCaptureResult, failureReason: FailureReason?) {
        self.selfieFile = result.selfieImage
        self.livenessFiles = result.livenessImages
        submitJob()
    }

    func didFinish(with error: any Error) {
        self.error = SmileIDError.selfieCaptureFailed
        updateProcessingState(.error)
    }
}
