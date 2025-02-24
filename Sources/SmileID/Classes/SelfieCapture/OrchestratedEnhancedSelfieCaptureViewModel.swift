import Foundation

class OrchestratedEnhancedSelfieCaptureViewModel: ObservableObject {
    let captureConfig = SelfieCaptureConfig.enhancedConfiguration
    let config: OrchestratedSelfieCaptureConfig
    let localMetadata: LocalMetadata

    weak var delegate: SmartSelfieResultDelegate?

    // MARK: Private Properties
    private var selfieImage: URL?
    private var livenessImages: [URL] = []
    private var apiResponse: SmartSelfieResponse?
    private var error: Error?
    private var submissionTask: Task<Void, Error>?
    private var failureReason: FailureReason?

    // MARK: UI Properties
    @Published private(set) var processingState: ProcessingState
    @Published public var errorMessageRes: String?
    @Published public var errorMessage: String?

    init(
        config: OrchestratedSelfieCaptureConfig,
        localMetadata: LocalMetadata
    ) {
        self.config = config
        self.localMetadata = localMetadata
    }

    deinit {
        invalidateSubmissionTask()
    }

    func configure(delegate: SmartSelfieResultDelegate) {
        self.delegate = delegate
    }

    private func handleSubmission() {
        DispatchQueue.main.async {
            self.processingState = .inProgress
        }
        guard submissionTask == nil else { return }
        submissionTask = Task {
            try await submitJob()
        }
    }

    private func handleCancelSelfieCapture() {
        invalidateSubmissionTask()
        if let error {
            delegate?.didError(error: error)
        } else {
            delegate?.didError(error: SmileIDError.operationCanceled("User cancelled"))
        }
    }
}

extension OrchestratedEnhancedSelfieCaptureViewModel: SelfieCaptureDelegate {
    func didFinish(with result: SelfieCaptureResult, failureReason: FailureReason?) {
        self.failureReason = failureReason
        handleSubmission()
    }
    
    func didFinish(with error: any Error) {
        onFinished()
    }
    
    
}

// MARK: Selfie Job Submission

extension OrchestratedEnhancedSelfieCaptureViewModel: SelfieSubmissionDelegate {
    public func submitJob() async throws {

        // Create an instance of SelfieSubmissionManager to manage the submission process
        let submissionManager = SelfieSubmissionManager(
            userId: userId,
            isEnroll: isEnroll,
            numLivenessImages: numLivenessImages,
            allowNewEnroll: allowNewEnroll,
            selfieImageUrl: selfieImageURL,
            livenessImages: livenessImages,
            extraPartnerParams: extraPartnerParams,
            localMetadata: localMetadata
        )
        submissionManager.delegate = self
        try await submissionManager.submitJob(failureReason: failureReason)
    }

    private func resetSelfieCaptureMetadata() {
        localMetadata.metadata.removeAllOfType(
            Metadatum.SelfieCaptureDuration.self)
        localMetadata.metadata.removeAllOfType(
            Metadatum.ActiveLivenessType.self)
    }

    public func onFinished() {
        if let selfieImageURL = selfieImageURL,
           let selfiePath = getRelativePath(from: selfieImageURL),
           livenessImages.count == numLivenessImages,
           !livenessImages.contains(where: { getRelativePath(from: $0) == nil }
           ) {
            let livenessImagesPaths = livenessImages.compactMap {
                getRelativePath(from: $0)
            }

            callback.didSucceed(
                selfieImage: selfiePath,
                livenessImages: livenessImagesPaths,
                apiResponse: apiResponse
            )
        } else if let error = error {
            callback.didError(error: error)
        }
    }

    // MARK: SelfieJobSubmissionDelegate Methods

    func submissionDidSucceed(_ apiResponse: SmartSelfieResponse) {
        invalidateSubmissionTask()
        HapticManager.shared.notification(type: .success)
        DispatchQueue.main.async {
            self.apiResponse = apiResponse
            self.selfieCaptureState = .processing(.success)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.onFinished(callback: self.onResult)
        }
    }

    func submissionDidFail(
        with error: Error,
        errorMessage: String?,
        errorMessageRes: String?,
        updatedSelfieImageUrl: URL?,
        updatedLivenessImages: [URL]
    ) {
        invalidateSubmissionTask()
        HapticManager.shared.notification(type: .error)
        DispatchQueue.main.async {
            self.error = error
            self.errorMessage = errorMessage
            self.errorMessageRes = errorMessageRes
            self.selfieCaptureState = .processing(.error)
            self.selfieImageURL = updatedSelfieImageUrl
            self.livenessImages = updatedLivenessImages
        }
    }

    func invalidateSubmissionTask() {
        submissionTask?.cancel()
        submissionTask = nil
    }
}
