import Combine
import Foundation

enum BiometricKycStep {
    case selfie
    case processing(ProcessingState)
}

class OrchestratedBiometricKycViewModel: ObservableObject {
    // MARK: - Input Properties

    private let userId: String
    private let jobId: String
    private let allowNewEnroll: Bool
    private let useStrictMode: Bool
    private var extraPartnerParams: [String: String]
    private let metadataManager: MetadataManager = .shared
    private var idInfo: IdInfo
    private var consentInformation: ConsentInformation

    // MARK: - Other Properties

    var selfieFile: URL?
    var livenessFiles: [URL]?
    private var error: Error?
    private var didSubmitBiometricJob: Bool = false
    private var networkRetries: Int = 0

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
        useStrictMode: Bool,
        consentInformation: ConsentInformation,
        extraPartnerParams: [String: String] = [:]
    ) {
        self.userId = userId
        self.jobId = jobId
        self.allowNewEnroll = allowNewEnroll
        self.useStrictMode = useStrictMode
        self.idInfo = idInfo
        self.consentInformation = consentInformation
        self.extraPartnerParams = extraPartnerParams
    }

    func onRetry() {
        if selfieFile != nil {
            incrementNetworkRetries()
            submitJob()
        } else {
            updateStep(.selfie)
        }
    }

    func onFinished(delegate: BiometricKycResultDelegate) {
        resetNetworkRetries()
        if let selfieFile = selfieFile,
           let livenessFiles = livenessFiles,
           let selfiePath = getRelativePath(from: selfieFile)
        {
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
                resetNetworkRetries()
                updateStep(.processing(.success))
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

        let zipData = try createZipData()

        let authResponse = try await authenticate()

        let preUploadResponse = try await prepareForUpload(authResponse: authResponse)

        try await uploadFiles(zipData: zipData, uploadUrl: preUploadResponse.uploadUrl)
        didSubmitBiometricJob = true

        try moveJobToSubmittedDirectory()
    }

    private func fetchRequiredFiles() throws {
        selfieFile = try LocalStorage.getFileByType(
            jobId: useStrictMode ? userId : jobId,
            fileType: FileType.selfie
        )

        livenessFiles = try LocalStorage.getFilesByType(
            jobId: useStrictMode ? userId : jobId,
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
            consentInformation: consentInformation,
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
            metadata: metadataManager.collectAllMetadata(),
            partnerParams: extraPartnerParams
        )
    }

    private func prepareForUpload(authResponse: AuthenticationResponse) async throws -> PrepUploadResponse {
        let prepUploadRequest = PrepUploadRequest(
            partnerParams: authResponse.partnerParams.copy(extras: extraPartnerParams),
            allowNewEnroll: allowNewEnroll,
            metadata: metadataManager.collectAllMetadata(),
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
            incrementNetworkRetries()
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
        try LocalStorage.moveToSubmittedJobs(jobId: jobId)
        if useStrictMode {
            try LocalStorage.moveToSubmittedJobs(jobId: userId)
        }
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
                jobId: jobId,
                error: smileIDError
            )
            if useStrictMode {
                _ = try LocalStorage.handleOfflineJobFailure(
                    jobId: userId,
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
            updateStep(.processing(.success))
        } else {
            didSubmitBiometricJob = false
            print("Error submitting job: \(smileIDError)")
            let (errorMessageRes, errorMessage) = toErrorMessage(error: smileIDError)
            error = smileIDError
            updateErrorMessages(errorMessage: errorMessage, errorMessageRes: errorMessageRes)
            updateStep(.processing(.error))
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

// MARK: - Metadata Helpers
extension OrchestratedBiometricKycViewModel {
    private func incrementNetworkRetries() {
        networkRetries += 1
        MetadataManager.shared.addMetadata(key: .networkRetries, value: String(networkRetries))
    }

    private func resetNetworkRetries() {
        MetadataManager.shared.removeMetadata(key: .networkRetries)
    }
}
