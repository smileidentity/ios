import Combine
import Foundation

enum BiometricKycStep {
    case selfie
    case processing(ProcessingState)
}

class OrchestratedBiometricKycViewModel: BaseSubmissionViewModel<BiometricKycResult> {
    // MARK: - Input Properties

    private let userId: String
    private let jobId: String
    private let allowNewEnroll: Bool
    private var extraPartnerParams: [String: String]
    private let localMetadata = LocalMetadata()
    private var idInfo: IdInfo

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
        let infoJson = try LocalStorage.createInfoJsonFile(
            jobId: jobId,
            idInfo: idInfo.copy(entered: true),
            selfie: selfieFile,
            livenessImages: livenessFiles
        )
        submitJob(jobId: jobId, skipApiSubmission: false, offlineMode: SmileID.allowOfflineMode)
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

    private func moveJobToSubmittedDirectory() throws {
        try LocalStorage.moveToSubmittedJobs(jobId: jobId)
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

    override public func createSubmission() throws -> BaseJobSubmission<BiometricKycResult> {
        guard let selfieImage = selfieFile,
              livenessFiles != nil
        else {
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

    override public func triggerProcessingState() {
        DispatchQueue.main.async { self.step = .processing(ProcessingState.inProgress) }
    }

    override public func handleSuccess(data _: BiometricKycResult) {
        DispatchQueue.main.async { self.step = .processing(ProcessingState.success) }
    }

    override public func handleError(error: Error) {
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

    override public func handleSubmissionFiles(jobId: String) throws {
        selfieFile = try LocalStorage.getFileByType(
            jobId: jobId,
            fileType: FileType.selfie,
            submitted: true
        )
        livenessFiles = try LocalStorage.getFilesByType(
            jobId: jobId,
            fileType: FileType.liveness,
            submitted: true
        ) ?? []
    }

    override public func handleOfflineSuccess() {
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
