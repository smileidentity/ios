import Combine
import Foundation

internal enum BiometricKycStep {
    case selfie
    case processing(ProcessingState)
}

internal class OrchestratedBiometricKycViewModel: ObservableObject {
    // MARK: - Input Properties

    private let userId: String
    private let jobId: String
    private let allowNewEnroll: Bool
    private var extraPartnerParams: [String: String]
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
        if selfieFile == nil {
            DispatchQueue.main.async { self.step = .selfie }
        } else {
            submitJob()
        }
    }

    func onFinished(delegate: BiometricKycResultDelegate) {
        if let selfieFile {
            if let livenessFiles {
                delegate.didSucceed(
                    selfieImage: getRelativePath(from: selfieFile)!,
                    livenessImages: livenessFiles.compactMap { getRelativePath(from: $0) },
                    didSubmitBiometricJob: didSubmitBiometricJob
                )
            }
        } else if let error {
            delegate.didError(error: error)
        } else {
            delegate.didError(error: SmileIDError.unknown("onFinish with no result or error"))
        }
    }

    func submitJob() {
        DispatchQueue.main.async { self.step = .processing(.inProgress) }
        Task {
            do {
                selfieFile = try LocalStorage.getFileByType(
                    jobId: jobId,
                    fileType: FileType.selfie
                )
                
                livenessFiles = try LocalStorage.getFilesByType(
                    jobId: jobId,
                    fileType: FileType.liveness
                )
                
                guard let selfieFile else {
                    // Set step to .selfieCapture so that the Retry button goes back to this step
                    DispatchQueue.main.async { self.step = .selfie }
                    error = SmileIDError.unknown("Error capturing selfie")
                    return
                }
                
                var allFiles = [URL]()
                let infoJson = try LocalStorage.createInfoJsonFile(
                    jobId: jobId,
                    idInfo: idInfo.copy(entered: true),
                    selfie: selfieFile,
                    livenessImages: livenessFiles
                )
                allFiles.append(contentsOf: [selfieFile, infoJson])
                if let livenessFiles {
                    allFiles.append(contentsOf: livenessFiles)
                }
                let zipData = try LocalStorage.zipFiles(at: allFiles)
                let authRequest = AuthenticationRequest(
                    jobType: .biometricKyc,
                    enrollment: false,
                    jobId: jobId,
                    userId: userId,
                    country: idInfo.country,
                    idType: idInfo.idType
                )
                if SmileID.allowOfflineMode {
                    try LocalStorage.saveOfflineJob(
                        jobId: jobId,
                        userId: userId,
                        jobType: .biometricKyc,
                        enrollment: false,
                        allowNewEnroll: allowNewEnroll,
                        partnerParams: extraPartnerParams
                    )
                }
                let authResponse = try await SmileID.api.authenticate(request: authRequest)
                let prepUploadRequest = PrepUploadRequest(
                    partnerParams: authResponse.partnerParams.copy(extras: extraPartnerParams),
                    allowNewEnroll: String(allowNewEnroll), // TODO: - Fix when Michael changes this to boolean
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
                _ = try await SmileID.api.upload(
                    zip: zipData,
                    to: prepUploadResponse.uploadUrl
                )
                didSubmitBiometricJob = true
                do {
                    try LocalStorage.moveToSubmittedJobs(jobId: self.jobId)
                } catch {
                    print("Error moving job to submitted directory: \(error)")
                    self.error = error
                    DispatchQueue.main.async { self.step = .processing(.error) }
                    return
                }
                DispatchQueue.main.async { self.step = .processing(.success) }
            } catch let error as SmileIDError {
                do {
                    _ = try LocalStorage.handleOfflineJobFailure(
                        jobId: self.jobId,
                        error: error
                    )
                } catch {
                    print("Error moving job to submitted directory: \(error)")
                    self.error = error
                    return
                }
                if SmileID.allowOfflineMode, LocalStorage.isNetworkFailure(error: error) {
                    didSubmitBiometricJob = true
                    DispatchQueue.main.async {
                        self.errorMessageRes = "Offline.Message"
                        self.step = .processing(.success)
                    }
                } else {
                    didSubmitBiometricJob = false
                    print("Error submitting job: \(error)")
                    let (errorMessageRes, errorMessage) = toErrorMessage(error: error)
                    self.error = error
                    self.errorMessageRes = errorMessageRes
                    self.errorMessage = errorMessage
                    DispatchQueue.main.async { self.step = .processing(.error) }
                }
            } catch {
                didSubmitBiometricJob = false
                print("Error submitting job: \(error)")
                self.error = error
                DispatchQueue.main.async { self.step = .processing(.error) }
            }
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
        DispatchQueue.main.async { self.step = .processing(.error) }
    }
}
