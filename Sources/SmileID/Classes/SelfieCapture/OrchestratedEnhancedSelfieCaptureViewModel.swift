import Foundation

class OrchestratedEnhancedSelfieCaptureViewModel: ObservableObject {
    let captureConfig = SelfieCaptureConfig.enhancedConfiguration
    let config: OrchestratedSelfieCaptureConfig
    let localMetadata: LocalMetadata

    weak var delegate: SmartSelfieResultDelegate?

    // MARK: Private Properties
    private var selfieImageURL: URL?
    private var livenessImages: [URL] = []
    private var apiResponse: SmartSelfieResponse?
    private var error: Error?
    private var submissionTask: Task<Void, Error>?
    private var failureReason: FailureReason?

    // MARK: UI Properties
    var selfieImage: UIImage?
    @Published private(set) var processingState: ProcessingState?
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
    
    func invalidateSubmissionTask() {
        submissionTask?.cancel()
        submissionTask = nil
    }

    func configure(delegate: SmartSelfieResultDelegate) {
        self.delegate = delegate
    }
    
    private func flipImageForPreview(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let contextSize = CGSize(
            width: image.size.width, height: image.size.height
        )
        UIGraphicsBeginImageContextWithOptions(contextSize, false, 1.0)
        defer {
            UIGraphicsEndImageContext()
        }
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }

        // Apply a 180° counterclockwise rotation
        // Translate the context to the center before rotating
        // to ensure the image rotates around its center
        context.translateBy(x: contextSize.width / 2, y: contextSize.height / 2)
        context.rotate(by: -.pi)

        // Draw the image
        context.draw(
            cgImage,
            in: CGRect(
                x: -image.size.width / 2, y: -image.size.height / 2,
                width: image.size.width, height: image.size.height
            )
        )

        // Get the new UIImage from the context
        let correctedImage = UIGraphicsGetImageFromCurrentImageContext()

        return correctedImage
    }

    private func handleSubmission() {
        guard let selfieImageURL, !livenessImages.isEmpty else {
            delegate?.didError(error: SmileIDError.selfieCaptureFailed)
            return
        }
        guard submissionTask == nil else { return }

        DispatchQueue.main.async {
            self.processingState = .inProgress
        }
        submissionTask = Task {
            try await submitJob(
                with: SelfieCaptureResult(
                    selfieImage: selfieImageURL,
                    livenessImages: livenessImages
                )
            )
        }
    }

    func handleCancelSelfieCapture() {
        invalidateSubmissionTask()
        if let error {
            delegate?.didError(error: error)
        } else {
            delegate?.didError(error: SmileIDError.operationCanceled("User cancelled"))
        }
    }
    
    func handleRetry() {
        handleSubmission()
    }
    
    public func onFinished() {
        if let selfieImageURL = selfieImageURL,
           let selfiePath = getRelativePath(from: selfieImageURL),
           livenessImages.count == captureConfig.numLivenessImages,
           !livenessImages.contains(where: { getRelativePath(from: $0) == nil }
           ) {
            let livenessImagesPaths = livenessImages.compactMap {
                getRelativePath(from: $0)
            }

            self.delegate?.didSucceed(
                selfieImage: selfiePath,
                livenessImages: livenessImagesPaths,
                apiResponse: apiResponse
            )
        } else if let error = error {
            self.delegate?.didError(error: error)
        }
    }
}

extension OrchestratedEnhancedSelfieCaptureViewModel: SelfieCaptureDelegate {
    func didFinish(with result: SelfieCaptureResult, failureReason: FailureReason?) {
        self.selfieImageURL = result.selfieImage
        self.livenessImages = result.livenessImages
        self.setPreviewSelfieImage(from: result.selfieImage)
        self.failureReason = failureReason
        handleSubmission()
    }

    func didFinish(with error: any Error) {
        self.error = error
        onFinished()
    }
    
    private func setPreviewSelfieImage(from imageURL: URL) {
        if let fileURL = try? LocalStorage.defaultDirectory.appendingPathComponent(imageURL.relativePath),
            let imageData = try? Data(contentsOf: fileURL),
            let uiImage = UIImage(data: imageData) {
            self.selfieImage = flipImageForPreview(uiImage)
        }
    }
}

// MARK: Selfie Job Submission

extension OrchestratedEnhancedSelfieCaptureViewModel: SelfieSubmissionDelegate {
    public func submitJob(with selfieCaptureResult: SelfieCaptureResult) async throws {

        // Create an instance of SelfieSubmissionManager to manage the submission process
        let submissionManager = SelfieSubmissionManager(
            config: config,
            captureConfig: captureConfig,
            captureResult: selfieCaptureResult,
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

    // MARK: SelfieJobSubmissionDelegate Methods

    func submissionDidSucceed(_ apiResponse: SmartSelfieResponse) {
        invalidateSubmissionTask()
        HapticManager.shared.notification(type: .success)
        DispatchQueue.main.async {
            self.apiResponse = apiResponse
            self.processingState = .success
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.onFinished()
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
            self.processingState = .error
            self.selfieImageURL = updatedSelfieImageUrl
            self.livenessImages = updatedLivenessImages
        }
    }
}
