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
    private var jobStatusResponse: BiometricKycJobStatusResponse?

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
        if let jobStatusResponse = jobStatusResponse,
           let selfieCaptureResultStore = selfieCaptureResultStore {
            delegate.didSucceed(
                selfieImage: selfieCaptureResultStore.selfie,
                livenessImages: selfieCaptureResultStore.livenessImages,
                jobStatusResponse: jobStatusResponse
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
                let infoJson = try LocalStorage.createInfoJson(
                    selfie: selfieImage,
                    livenessImages: livenessImages,
                    idInfo: idInfo
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
                let _ = try await SmileID.api.upload(
                    zip: zip,
                    to: prepUploadResponse.uploadUrl
                ).async()
                let jobStatusRequest = JobStatusRequest(
                    userId: userId,
                    jobId: jobId,
                    includeImageLinks: false,
                    includeHistory: false,
                    timestamp: authResponse.timestamp,
                    signature: authResponse.signature
                )
                jobStatusResponse = try await SmileID.api.getJobStatus(
                    request: jobStatusRequest
                ).async()
                DispatchQueue.main.async { self.step = .processing(.success) }
            } catch {
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
        jobStatusResponse: SmartSelfieJobStatusResponse?
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
