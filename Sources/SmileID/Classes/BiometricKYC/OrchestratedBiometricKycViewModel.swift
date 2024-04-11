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
    private var error: Error?
    private var selfieCaptureResultStore: SelfieCaptureResultStore?
    private var didSubmitBiometricJob: Bool = false

    // MARK: - UI Properties
    @Published @MainActor private (set) var step: BiometricKycStep = .selfie

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
        if selfieCaptureResultStore == nil {
            DispatchQueue.main.async { self.step = .selfie }
        } else {
            submitJob(selfieCaptureResultStore: selfieCaptureResultStore!)
        }
    }

    func onFinished(delegate: BiometricKycResultDelegate) {
        if let selfieCaptureResultStore = selfieCaptureResultStore {
            delegate.didSucceed(
                selfieImage: selfieCaptureResultStore.selfie,
                livenessImages: selfieCaptureResultStore.livenessImages,
                didSubmitBiometricJob: self.didSubmitBiometricJob
            )
        } else if let error = error {
            delegate.didError(error: error)
        } else {
            delegate.didError(error: SmileIDError.unknown("onFinish with no result or error"))
        }
    }

    func submitJob(selfieCaptureResultStore: SelfieCaptureResultStore) {
        DispatchQueue.main.async { self.step = .processing(.inProgress) }
        Task {
            do {
                let livenessImages = selfieCaptureResultStore.livenessImages
                let selfieImage = selfieCaptureResultStore.selfie
                let infoJson = try LocalStorage.createInfoJsonFile(
                    jobId: jobId,
                    idInfo: idInfo.copy(entered: true),
                    selfie: selfieImage,
                    livenessImages: livenessImages
                )
                let zipUrl = try LocalStorage.zipFiles(
                    at: livenessImages + [selfieImage] + [infoJson]
                )
                let zip = try Data(contentsOf: zipUrl)
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
                let authResponse = try await SmileID.api.authenticate(request: authRequest).async()
                let prepUploadRequest = PrepUploadRequest(
                    partnerParams: authResponse.partnerParams.copy(extras: extraPartnerParams),
                    allowNewEnroll: String(allowNewEnroll), // TODO - Fix when Michael changes this to boolean
                    timestamp: authResponse.timestamp,
                    signature: authResponse.signature
                )
                let prepUploadResponse = try await SmileID.api.prepUpload(
                    request: prepUploadRequest
                ).async()
                _ = try await SmileID.api.upload(
                    zip: zip,
                    to: prepUploadResponse.uploadUrl
                ).async()
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
                    try LocalStorage.handleOfflineJobFailure(
                        jobId: self.jobId,
                        error: error
                    )
                } catch {
                    print("Error moving job to submitted directory: \(error)")
                    self.error = error
                    return
                }
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
        selfieImage: URL,
        livenessImages: [URL],
        didSubmitSmartSelfieJob: Bool
    ) {
        selfieCaptureResultStore = SelfieCaptureResultStore(
            selfie: selfieImage,
            livenessImages: livenessImages
        )
        if let selfieCaptureResultStore = selfieCaptureResultStore {
            submitJob(selfieCaptureResultStore: selfieCaptureResultStore)
        } else {
            error = SmileIDError.unknown("Failed to save selfie capture result")
            DispatchQueue.main.async { self.step = .processing(.error) }
        }
    }

    func didError(error: Error) {
        self.error = SmileIDError.unknown("Failed to capture selfie")
        DispatchQueue.main.async { self.step = .processing(.error) }
    }
}
