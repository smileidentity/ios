import Foundation

class OrchestratedSelfieCaptureViewModel: ObservableObject {
    let captureConfig = SelfieCaptureConfig.defaultConfiguration
    let config: OrchestratedSelfieCaptureConfig
    let localMetadata: LocalMetadata

    weak var delegate: SmartSelfieResultDelegate?

    // MARK: Private Properties
    private var selfieImage: URL?
    private var livenessImages: [URL] = []
    private var apiResponse: SmartSelfieResponse?
    private var error: Error?

    // MARK: UI Outputs
    @Published public private(set) var processingState: ProcessingState?
    /// we use `errorMessageRes` to map to the actual code to the stringRes to allow localization,
    /// and use `errorMessage` to show the actual platform error message that we show if
    /// `errorMessageRes` is not set by the partner
    @Published public var errorMessageRes: String?
    @Published public var errorMessage: String?

    init(
        config: OrchestratedSelfieCaptureConfig,
        localMetadata: LocalMetadata = LocalMetadata()
    ) {
        self.config = config
        self.localMetadata = localMetadata
    }

    public func submitJob() {
        localMetadata.addMetadata(
            Metadatum.ActiveLivenessType(livenessType: LivenessType.smile))
        if config.skipApiSubmission {
            DispatchQueue.main.async { self.processingState = .success }
            return
        }
        DispatchQueue.main.async { self.processingState = .inProgress }
        Task {
            do {
                let jobType =
                config.isEnroll
                ? JobType.smartSelfieEnrollment
                : JobType.smartSelfieAuthentication
                let authRequest = AuthenticationRequest(
                    jobType: jobType,
                    enrollment: config.isEnroll,
                    jobId: config.jobId,
                    userId: config.userId
                )
                if SmileID.allowOfflineMode {
                    try LocalStorage.saveOfflineJob(
                        jobId: config.jobId,
                        userId: config.userId,
                        jobType: jobType,
                        enrollment: config.isEnroll,
                        allowNewEnroll: config.allowNewEnroll,
                        localMetadata: localMetadata,
                        partnerParams: config.extraPartnerParams
                    )
                }
                let authResponse = try await SmileID.api.authenticate(
                    request: authRequest)

                var smartSelfieLivenessImages = [MultipartBody]()
                var smartSelfieImage: MultipartBody?
                if let selfieImage, let selfieData = try? Data(contentsOf: selfieImage),
                   let media = MultipartBody(
                    withImage: selfieData,
                    forKey: selfieImage.lastPathComponent,
                    forName: selfieImage.lastPathComponent
                   ) {
                    smartSelfieImage = media
                }

                let livenessImageInfos = livenessImages.compactMap { liveness -> MultipartBody? in
                    if let data = try? Data(contentsOf: liveness) {
                        return MultipartBody(
                            withImage: data,
                            forKey: liveness.lastPathComponent,
                            forName: liveness.lastPathComponent
                        )
                    }
                    return nil
                }

                smartSelfieLivenessImages.append(
                    contentsOf: livenessImageInfos.compactMap { $0 })

                guard let smartSelfieImage = smartSelfieImage,
                      smartSelfieLivenessImages.count == captureConfig.numLivenessImages
                else {
                    throw SmileIDError.unknown("Selfie capture failed")
                }

                let response =
                if config.isEnroll {
                    try await SmileID.api.doSmartSelfieEnrollment(
                        signature: authResponse.signature,
                        timestamp: authResponse.timestamp,
                        selfieImage: smartSelfieImage,
                        livenessImages: smartSelfieLivenessImages,
                        userId: config.userId,
                        partnerParams: config.extraPartnerParams,
                        callbackUrl: SmileID.callbackUrl,
                        sandboxResult: nil,
                        allowNewEnroll: config.allowNewEnroll,
                        failureReason: nil,
                        metadata: localMetadata.metadata
                    )
                } else {
                    try await SmileID.api.doSmartSelfieAuthentication(
                        signature: authResponse.signature,
                        timestamp: authResponse.timestamp,
                        userId: config.userId,
                        selfieImage: smartSelfieImage,
                        livenessImages: smartSelfieLivenessImages,
                        partnerParams: config.extraPartnerParams,
                        callbackUrl: SmileID.callbackUrl,
                        sandboxResult: nil,
                        failureReason: nil,
                        metadata: localMetadata.metadata
                    )
                }
                apiResponse = response
                do {
                    try LocalStorage.moveToSubmittedJobs(jobId: self.config.jobId)
                    self.selfieImage = try LocalStorage.getFileByType(
                        jobId: config.jobId,
                        fileType: FileType.selfie,
                        submitted: true
                    )
                    self.livenessImages =
                    try LocalStorage.getFilesByType(
                        jobId: config.jobId,
                        fileType: FileType.liveness,
                        submitted: true
                    ) ?? []
                } catch {
                    print("Error moving job to submitted directory: \(error)")
                    self.error = error
                }
                DispatchQueue.main.async { self.processingState = .success }
            } catch let error as SmileIDError {
                do {
                    let didMove = try LocalStorage.handleOfflineJobFailure(
                        jobId: self.config.jobId,
                        error: error
                    )
                    if didMove {
                        self.selfieImage = try LocalStorage.getFileByType(
                            jobId: config.jobId,
                            fileType: FileType.selfie,
                            submitted: true
                        )
                        self.livenessImages =
                        try LocalStorage.getFilesByType(
                            jobId: config.jobId,
                            fileType: FileType.liveness,
                            submitted: true
                        ) ?? []
                    }
                } catch {
                    print("Error moving job to submitted directory: \(error)")
                    self.error = error
                    return
                }
                if SmileID.allowOfflineMode,
                   SmileIDError.isNetworkFailure(error: error) {
                    DispatchQueue.main.async {
                        self.errorMessageRes = "Offline.Message"
                        self.processingState = .success
                    }
                } else {
                    print("Error submitting job: \(error)")
                    let (errorMessageRes, errorMessage) = toErrorMessage(
                        error: error)
                    self.error = error
                    self.errorMessageRes = errorMessageRes
                    self.errorMessage = errorMessage
                    DispatchQueue.main.async { self.processingState = .error }
                }
            } catch {
                print("Error submitting job: \(error)")
                self.error = error
                DispatchQueue.main.async { self.processingState = .error }
            }
        }
    }

    public func onFinished() {
        guard let delegate = delegate else { return }
        if let selfiePath = getRelativePath(from: selfieImage),
           livenessImages.count == captureConfig.numLivenessImages,
           !livenessImages.contains(where: { getRelativePath(from: $0) == nil }
           ) {
            let livenessImagesPaths = livenessImages.compactMap {
                getRelativePath(from: $0)
            }

            delegate.didSucceed(
                selfieImage: selfiePath,
                livenessImages: livenessImagesPaths,
                apiResponse: apiResponse
            )
        } else if let error = error {
            delegate.didError(error: error)
        } else {
            delegate.didError(error: SmileIDError.unknown("Unknown error"))
        }
    }
}

extension OrchestratedSelfieCaptureViewModel: SelfieCaptureDelegate {
    func didFinishWith(result: SelfieCaptureResult, error: (any Error)?) {
        if let error = error {
            self.error = error
        } else {
            selfieImage = result.selfieImage
            livenessImages = result.livenessImages
            submitJob()
        }
    }
}
