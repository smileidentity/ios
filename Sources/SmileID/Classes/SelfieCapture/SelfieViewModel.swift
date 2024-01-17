import Foundation

// let INTRA_IMAGE_MIN_DELAY: TimeInterval = 0.35

class SelfieViewModel: ObservableObject {
    private let isEnroll: Bool
    private let userId: String
    private let jobId: String
    private let allowNewEnroll: Bool
    private let skipApiSubmission: Bool
    private let extraPartnerParams: [String: String]

    var cameraManager = CameraManager(orientation: .portrait)
    var shouldAnalyzeImages = true
    var lastAutoCaptureTime = Date()
    var selfieImage: URL?
    var livenessImages: [URL]?
    var jobStatusResponse: SmartSelfieJobStatusResponse?
    var error: Error?

    // UI Properties
    @Published var directive: String = "Instructions.Unstable"
    @Published var processingState: ProcessingState?
    @Published var selfieToConfirm: Data?
    @Published var captureProgress: Double = 0
    @Published var useBackCamera = false {
        // This is toggled by a Binding
        didSet { switchCamera() }
    }
    
    init(
        isEnroll: Bool,
        userId: String,
        jobId: String,
        allowNewEnroll: Bool,
        skipApiSubmission: Bool,
        extraPartnerParams: [String: String]
    ) {
        self.isEnroll = isEnroll
        self.userId = userId
        self.jobId = jobId
        self.allowNewEnroll = allowNewEnroll
        self.skipApiSubmission = skipApiSubmission
        self.extraPartnerParams = extraPartnerParams
        // TODO: Save this to AnyCancellable
        let cancellable = self.cameraManager.sampleBufferPublisher
            .receive(on: DispatchQueue.global())
            .compactMap { $0 }
            .sink(receiveValue: analyzeImage)
    }
    
    func analyzeImage(image: CVImageBuffer) {
        let elapsedtime = Date().timeIntervalSince(lastAutoCaptureTime)
        if (!shouldAnalyzeImages || elapsedtime < 0.35) {
            return
        }
        FaceDetector().detect(pixelBuffer: image)
    }

    func switchCamera() {
        self.cameraManager.switchCamera(to: useBackCamera ? .back : .front)
    }

    func onSelfieRejected() {
        DispatchQueue.main.async {
            self.captureProgress = 0
            self.processingState = nil
            self.selfieToConfirm = nil
        }
        selfieImage = nil
        livenessImages = nil
        jobStatusResponse = nil
        shouldAnalyzeImages = true
    }

    func onRetry() {
        // If selfie file is present, all captures were completed, so we're retrying a network issue
        if let _ = selfieImage, let _ = livenessImages {
            submitJob()
        } else {
            shouldAnalyzeImages = true
            DispatchQueue.main.async { self.processingState = nil }
        }
    }

    func submitJob() {
        if (skipApiSubmission) {
            DispatchQueue.main.async { self.processingState = .success }
            return
        }
        DispatchQueue.main.async { self.processingState = .inProgress }
        Task {
            do {
                guard let selfieImage, let livenessImages else {
                    throw SmileIDError.unknown("Selfie capture failed")
                }
                let infoJson = try LocalStorage.createInfoJson(
                    selfie: selfieImage,
                    livenessImages: livenessImages
                )
                let zipUrl = try LocalStorage.zipFiles(
                    at: livenessImages + [selfieImage] + [infoJson]
                )
                let zip = try Data(contentsOf: zipUrl)
                let jobType = isEnroll ? JobType.smartSelfieEnrollment : JobType.smartSelfieAuthentication
                let authRequest = AuthenticationRequest(
                    jobType: jobType,
                    enrollment: isEnroll,
                    jobId: jobId,
                    userId: userId
                )
                let authResponse = try await SmileID.api.authenticate(request: authRequest).async()
                let prepUploadRequest = PrepUploadRequest(
                    partnerParams: authResponse.partnerParams.copy(extras: extraPartnerParams),
                    allowNewEnroll: String(allowNewEnroll),
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
                DispatchQueue.main.async { self.processingState = .success }
            } catch {
                print("Error submitting job: \(error)")
                self.error = error
                DispatchQueue.main.async { self.processingState = .error }
            }
        }
    }

    func onFinished(callback: SmartSelfieResultDelegate) {
        if let selfieImage, let livenessImages {
            callback.didSucceed(
                selfieImage: selfieImage,
                livenessImages: livenessImages,
                jobStatusResponse: jobStatusResponse
            )
        } else if let error {
            callback.didError(error: error)
        } else {
            callback.didError(error: SmileIDError.unknown("Unknown error"))
        }
    }
}
