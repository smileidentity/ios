import Combine
import Foundation

internal enum BiometricKycStep {
    case selfie
    case processing(ProcessingState)
}

internal class OrchestratedBiometricKycViewModel: BaseSubmissionViewModel<BiometricKycResult> {
    // MARK: - Input Properties

    private let userId: String
    private let jobId: String
    private let allowNewEnroll: Bool
    private var extraPartnerParams: [String: String]
    private let localMetadata = LocalMetadata()
    private var idInfo: IdInfo

    // MARK: - Other Properties

    internal var selfieFile: URL?
    internal var livenessFiles: [URL]?
    private var error: Error?
    private var didSubmitBiometricJob: Bool = false

    // MARK: - UI Properties

    /// we use `errorMessageRes` to map to the actual code to the stringRes to allow localization,
    /// and use `errorMessage` to show the actual platform error message that we show if
    /// `errorMessageRes` is not set by the partner
    @Published var errorMessageRes: String?
    @Published var errorMessage: String?
    @Published @MainActor private(set) var step: BiometricKycStep = .selfie

    init(
        userId: String,
        jobId: String,
        allowNewEnroll: Bool,
        idInfo: IdInfo,
        extraPartnerParams: [String: String] = [:]
    ) {
        self.userId = userId
        self.jobId = jobId
        self.allowNewEnroll = allowNewEnroll
        self.idInfo = idInfo
        self.extraPartnerParams = extraPartnerParams
    }

    func onRetry() {
        if selfieFile != nil {
            submitJob()
        } else {
            updateStep(.selfie)
        }
    }

    func onFinished(delegate: BiometricKycResultDelegate) {
        if let selfieFile = selfieFile,
            let livenessFiles = livenessFiles,
            let selfiePath = getRelativePath(from: selfieFile) {
            delegate.didSucceed(
                selfieImage: selfiePath,
                livenessImages: livenessFiles.compactMap { getRelativePath(from: $0) },
                didSubmitBiometricJob: didSubmitBiometricJob
            )
        } else if let error {
            delegate.didError(error: error)
        } else {
            delegate.didError(error: SmileIDError.unknown("onFinish with no result or error"))
        }
    }

    func submitJob() {
        updateStep(.processing(.inProgress))
        Task {
            do {
                try await handleJobSubmission()
            } catch let error as SmileIDError {
                handleSubmissionFailure(error)
            } catch {
                didSubmitBiometricJob = false
                print("Error submitting job: \(error)")
                self.error = error
                updateStep(.processing(.error))
            }
        }
    }

    private func handleJobSubmission() async throws {
        try fetchRequiredFiles()
        submitJob(jobId: self.jobId,skipApiSubmission: false,offlineMode: SmileID.allowOfflineMode)
    }

    private func fetchRequiredFiles() throws {
        selfieFile = try LocalStorage.getFileByType(
            jobId: jobId,
            fileType: FileType.selfie
        )

        livenessFiles = try LocalStorage.getFilesByType(
            jobId: jobId,
            fileType: FileType.liveness
        )

        guard selfieFile != nil else {
            // Set step to .selfieCapture so that the Retry button goes back to this step
            updateStep(.selfie)
            error = SmileIDError.unknown("Error capturing selfie")
            return
        }
    }

    private func createZipData() throws -> Data {
        var allFiles = [URL]()
        let infoJson = try LocalStorage.createInfoJsonFile(
            jobId: jobId,
            idInfo: idInfo.copy(entered: true),
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
            jobId: jobId,
            userId: userId,
            country: idInfo.country,
            idType: idInfo.idType
        )

        if SmileID.allowOfflineMode {
            try saveOfflineJobIfAllowed()
        }

        return try await SmileID.api.authenticate(request: authRequest)
    }

    private func saveOfflineJobIfAllowed() throws {
        try LocalStorage.saveOfflineJob(
            jobId: jobId,
            userId: userId,
            jobType: .biometricKyc,
            enrollment: false,
            allowNewEnroll: allowNewEnroll,
            localMetadata: localMetadata,
            partnerParams: extraPartnerParams
        )
    }

    private func prepareForUpload(authResponse: AuthenticationResponse) async throws -> PrepUploadResponse {
        let prepUploadRequest = PrepUploadRequest(
            partnerParams: authResponse.partnerParams.copy(extras: extraPartnerParams),
            allowNewEnroll: String(allowNewEnroll),  // TODO: - Fix when Michael changes this to boolean
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
        try LocalStorage.moveToSubmittedJobs(jobId: self.jobId)
    }

    private func updateStep(_ newStep: BiometricKycStep) {
        DispatchQueue.main.async {
            self.step = newStep
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
                jobId: self.jobId,
                error: smileIDError
            )
        } catch {
            print("Error moving job to submitted directory: \(error)")
            self.error = smileIDError
            return
        }

        if SmileID.allowOfflineMode, SmileIDError.isNetworkFailure(error: smileIDError) {
            didSubmitBiometricJob = true
            updateErrorMessages(errorMessageRes: "Offline.Message")
            updateStep(.processing(.success))
        } else {
            didSubmitBiometricJob = false
            print("Error submitting job: \(smileIDError)")
            let (errorMessageRes, errorMessage) = toErrorMessage(error: smileIDError)
            self.error = smileIDError
            updateErrorMessages(errorMessage: errorMessage, errorMessageRes: errorMessageRes)
            updateStep(.processing(.error))
        }
    }
    
    public override func createSubmission() throws -> BaseJobSubmission<BiometricKycResult> {
        guard let selfieImage = selfieFile,
              livenessFiles != nil else {
            throw SmileIDError.unknown("Selfie images missing")
        }
        return BiometricKYCSubmission(
            userId: userId,
            jobId: jobId,
            allowNewEnroll: allowNewEnroll,
            livenessFiles: livenessFiles,
            selfieFile: selfieImage,
            idInfo: idInfo,
            extraPartnerParams: extraPartnerParams,
            metadata: localMetadata.metadata
        )
    }
    
    public override func triggerProcessingState() {
        DispatchQueue.main.async { self.step = .processing(ProcessingState.inProgress) }
    }
    
    public override func handleSuccess(data: BiometricKycResult) {
        DispatchQueue.main.async { self.step = .processing(ProcessingState.success) }
    }
    
    public override func handleError(error: Error) {
        if let smileError = error as? SmileIDError {
            print("Error submitting job: \(error)")
            let (errorMessageRes, errorMessage) = toErrorMessage(error: smileError)
            self.error = error
            self.errorMessageRes = errorMessageRes
            self.errorMessage = errorMessage
            DispatchQueue.main.async { self.step = .processing(ProcessingState.error) }
        } else {
            print("Error submitting job: \(error)")
            self.error = error
            DispatchQueue.main.async { self.step = .processing(ProcessingState.error) }
        }
    }
    
    public override func handleSubmissionFiles(jobId: String) throws {
        self.selfieFile = try LocalStorage.getFileByType(
            jobId: jobId,
            fileType: FileType.selfie,
            submitted: true
        )
        self.livenessFiles = try LocalStorage.getFilesByType(
            jobId: jobId,
            fileType: FileType.liveness,
            submitted: true
        ) ?? []
    }
    
    public override func handleOfflineSuccess() {
        DispatchQueue.main.async {
            self.errorMessageRes = "Offline.Message"
            self.step = .processing(ProcessingState.success)
        }
    }
}

extension OrchestratedBiometricKycViewModel: SmartSelfieResultDelegate {
    func didSucceed(
        selfieImage _: URL,
        livenessImages _: [URL],
        apiResponse _: SmartSelfieResponse?
    ) {
        submitJob()
    }

    func didError(error _: Error) {
        error = SmileIDError.unknown("Error capturing selfie")
        updateStep(.processing(.error))
    }
}
