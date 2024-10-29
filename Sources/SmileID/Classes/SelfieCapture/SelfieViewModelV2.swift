import ARKit
import Combine
import Foundation

public class SelfieViewModelV2: ObservableObject {
    // MARK: Dependencies
    let cameraManager = CameraManager.shared
    let faceDetector = FaceDetectorV2()
    private let faceValidator = FaceValidator()
    var livenessCheckManager = LivenessCheckManager()
    private var subscribers = Set<AnyCancellable>()
    private var guideAnimationDelayTimer: Timer?
    private let metadataTimerStart = MonotonicTime()

    // MARK: Private Properties
    private var faceLayoutGuideFrame = CGRect(x: 0, y: 0, width: 200, height: 300)
    private var elapsedGuideAnimationDelay: TimeInterval = 0
    var selfieImage: UIImage?
    var selfieImageURL: URL? {
        didSet {
            DispatchQueue.main.async {
                self.selfieCaptured = self.selfieImage != nil
            }
        }
    }
    var livenessImages: [URL] = []
    private var hasDetectedValidFace: Bool = false
    private var shouldBeginLivenessChallenge: Bool {
        hasDetectedValidFace && selfieImage != nil && livenessCheckManager.currentTask != nil
    }
    private var shouldSubmitJob: Bool {
        selfieImage != nil && livenessImages.count == numLivenessImages
    }
    private var forcedFailure: Bool = false
    private var apiResponse: SmartSelfieResponse?
    private var error: Error?
    @Published public var errorMessageRes: String?
    @Published public var errorMessage: String?

    // MARK: Constants
    private let livenessImageSize = 320
    private let selfieImageSize = 640
    private let numLivenessImages = 6
    private let guideAnimationDelayTime: TimeInterval = 3

    // MARK: UI Properties
    @Published var unauthorizedAlert: AlertState?
    @Published private(set) var userInstruction: SelfieCaptureInstruction?
    @Published private(set) var faceInBounds: Bool = false
    @Published private(set) var selfieCaptured: Bool = false
    @Published private(set) var showGuideAnimation: Bool = false
    @Published var showProcessingView: Bool = false
    @Published public private(set) var processingState: ProcessingState?

    // MARK: Injected Properties
    private let isEnroll: Bool
    private let userId: String
    private let jobId: String
    private let allowNewEnroll: Bool
    private let skipApiSubmission: Bool
    private let extraPartnerParams: [String: String]
    private let useStrictMode: Bool
    private let onResult: SmartSelfieResultDelegate
    private var localMetadata: LocalMetadata

    public init(
        isEnroll: Bool,
        userId: String,
        jobId: String,
        allowNewEnroll: Bool,
        skipApiSubmission: Bool,
        extraPartnerParams: [String: String],
        useStrictMode: Bool,
        onResult: SmartSelfieResultDelegate,
        localMetadata: LocalMetadata
    ) {
        self.isEnroll = isEnroll
        self.userId = userId
        self.jobId = jobId
        self.allowNewEnroll = allowNewEnroll
        self.skipApiSubmission = skipApiSubmission
        self.extraPartnerParams = extraPartnerParams
        self.useStrictMode = useStrictMode
        self.onResult = onResult
        self.localMetadata = localMetadata
        self.initialSetup()
    }

    deinit {
        stopGuideAnimationDelayTimer()
    }

    private func initialSetup() {
        self.faceValidator.delegate = self
        self.faceDetector.resultDelegate = self
        self.livenessCheckManager.selfieViewModel = self

        self.faceValidator.setLayoutGuideFrame(with: faceLayoutGuideFrame)
        self.userInstruction = .headInFrame

        livenessCheckManager.$lookLeftProgress
            .merge(
                with: livenessCheckManager.$lookRightProgress,
                livenessCheckManager.$lookUpProgress
            )
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.resetGuideAnimationDelayTimer()
                }
            }
            .store(in: &subscribers)

        cameraManager.$status
            .receive(on: DispatchQueue.main)
            .filter { $0 == .unauthorized }
            .map { _ in AlertState.cameraUnauthorized }
            .sink { alert in self.unauthorizedAlert = alert }
            .store(in: &subscribers)

        cameraManager.sampleBufferPublisher
            // Drop the first ~2 seconds to allow the user to settle in
            .throttle(
                for: 0.35,
                scheduler: DispatchQueue.global(qos: .userInitiated),
                latest: true
            )
            .dropFirst(5)
            .compactMap { $0 }
            .sink(receiveValue: analyzeFrame)
            .store(in: &subscribers)
    }

    private func analyzeFrame(imageBuffer: CVPixelBuffer) {
        faceDetector.processImageBuffer(imageBuffer)
        if hasDetectedValidFace && selfieImage == nil {
            captureSelfieImage(imageBuffer)
            livenessCheckManager.initiateLivenessCheck()
        }

        livenessCheckManager.captureImage = { [weak self] in
            self?.captureLivenessImage(imageBuffer)
        }
    }

    // MARK: Actions
    func perform(action: SelfieViewModelAction) {
        switch action {
        case let .windowSizeDetected(windowRect):
            handleWindowSizeChanged(toRect: windowRect)
        case .activeLivenessCompleted:
            handleSubmission(forcedFailure: false)
        case .activeLivenessTimeout:
            handleSubmission(forcedFailure: true)
        case .onViewAppear:
            handleViewAppeared()
        case .jobProcessingDone:
            onFinished(callback: onResult)
        case .retryJobSubmission:
            handleSubmission(forcedFailure: false)
        case .openApplicationSettings:
            openSettings()
        case let .handleError(error):
            handleError(error)
        }
    }

    private func publishUserInstruction(_ instruction: SelfieCaptureInstruction?) {
        if self.userInstruction != instruction {
            self.userInstruction = instruction
            self.resetGuideAnimationDelayTimer()
        }
    }
}

// MARK: Action Handlers
extension SelfieViewModelV2 {
    private func resetGuideAnimationDelayTimer() {
        elapsedGuideAnimationDelay = 0
        showGuideAnimation = false
        guard guideAnimationDelayTimer == nil else { return }
        guideAnimationDelayTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.elapsedGuideAnimationDelay += 1
            if self.elapsedGuideAnimationDelay == self.guideAnimationDelayTime {
                self.showGuideAnimation = true
                self.stopGuideAnimationDelayTimer()
            }
        }
    }

    private func stopGuideAnimationDelayTimer() {
        guard guideAnimationDelayTimer != nil else { return }
        guideAnimationDelayTimer?.invalidate()
        guideAnimationDelayTimer = nil
    }

    private func handleViewAppeared() {
        cameraManager.switchCamera(to: .front)
        resetGuideAnimationDelayTimer()
        resetSelfieCaptureState()
    }

    private func resetSelfieCaptureState() {
        selfieImage = nil
        livenessImages = []
        processingState = nil
        forcedFailure = false
    }

    private func handleWindowSizeChanged(toRect: CGSize) {
        faceLayoutGuideFrame = CGRect(
            x: (toRect.width / 2) - faceLayoutGuideFrame.width / 2,
            y: (toRect.height / 2) - faceLayoutGuideFrame.height / 2,
            width: faceLayoutGuideFrame.width,
            height: faceLayoutGuideFrame.height
        )
        faceValidator.setLayoutGuideFrame(with: faceLayoutGuideFrame)
    }

    private func captureSelfieImage(_ pixelBuffer: CVPixelBuffer) {
        do {
            guard
                let imageData = ImageUtils.resizePixelBufferToHeight(
                    pixelBuffer,
                    height: selfieImageSize,
                    orientation: .up
                )
            else {
                throw SmileIDError.unknown("Error resizing selfie image")
            }
            self.selfieImage = UIImage(data: imageData)
            self.selfieImageURL = try LocalStorage.createSelfieFile(jobId: jobId, selfieFile: imageData)
        } catch {
            handleError(error)
        }
    }

    private func captureLivenessImage(_ pixelBuffer: CVPixelBuffer) {
        do {
            guard
                let imageData = ImageUtils.resizePixelBufferToHeight(
                    pixelBuffer,
                    height: livenessImageSize,
                    orientation: .up
                )
            else {
                throw SmileIDError.unknown("Error resizing liveness image")
            }
            let imageUrl = try LocalStorage.createLivenessFile(jobId: jobId, livenessFile: imageData)
            livenessImages.append(imageUrl)
        } catch {
            handleError(error)
        }
    }

    private func handleError(_ error: Error) {
        print(error.localizedDescription)
    }

    private func handleSubmission(forcedFailure: Bool) {
        self.forcedFailure = forcedFailure
        Task {
            try await submitJob()
        }
    }

    private func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
    }
}

// MARK: FaceDetectorResultDelegate Methods
extension SelfieViewModelV2: FaceDetectorResultDelegate {
    func faceDetector(
        _ detector: FaceDetectorV2,
        didDetectFace faceGeometry: FaceGeometryData,
        withFaceQuality faceQuality: Float,
        selfieQuality: SelfieQualityData,
        brightness: Int
    ) {
        faceValidator
            .validate(
                faceGeometry: faceGeometry,
                selfieQuality: selfieQuality,
                brightness: brightness,
                currentLivenessTask: self.livenessCheckManager.currentTask
            )
        if shouldBeginLivenessChallenge {
            livenessCheckManager.processFaceGeometry(faceGeometry)
        }
    }

    func faceDetector(_ detector: FaceDetectorV2, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.publishUserInstruction(.headInFrame)
        }
        print(error.localizedDescription)
    }
}

// MARK: FaceValidatorDelegate Methods
extension SelfieViewModelV2: FaceValidatorDelegate {
    func updateValidationResult(_ result: FaceValidationResult) {
        DispatchQueue.main.async {
            self.faceInBounds = result.faceInBounds
            self.hasDetectedValidFace = result.hasDetectedValidFace
            self.publishUserInstruction(result.userInstruction)
        }
    }
}

// MARK: Selfie Job Submission
extension SelfieViewModelV2: SelfieSubmissionDelegate {
    public func submitJob() async throws {
        DispatchQueue.main.async {
            self.processingState = .inProgress
            self.showProcessingView = true
        }

        // Add metadata before submission
        addSelfieCaptureDurationMetaData()

        if skipApiSubmission {
            // Skip API submission and update processing state to success
            self.processingState = .success
            return
        }
        // Create an instance of SelfieSubmissionManager to manage the submission process
        let submissionManager = SelfieSubmissionManager(
            userId: self.userId,
            jobId: self.jobId,
            isEnroll: self.isEnroll,
            numLivenessImages: self.numLivenessImages,
            allowNewEnroll: self.allowNewEnroll,
            selfieImage: self.selfieImageURL,
            livenessImages: self.livenessImages,
            extraPartnerParams: self.extraPartnerParams,
            localMetadata: self.localMetadata
        )
        submissionManager.delegate = self
        try await submissionManager.submitJob(forcedFailure: self.forcedFailure)
    }

    private func addSelfieCaptureDurationMetaData() {
        localMetadata.addMetadata(
            Metadatum.SelfieCaptureDuration(duration: metadataTimerStart.elapsedTime()))
    }

    public func onFinished(callback: SmartSelfieResultDelegate) {
        if let selfieImage = selfieImage,
           let selfiePath = getRelativePath(from: selfieImageURL),
            livenessImages.count == numLivenessImages,
            !livenessImages.contains(where: { getRelativePath(from: $0) == nil }) {
            let livenessImagesPaths = livenessImages.compactMap { getRelativePath(from: $0) }

            callback.didSucceed(
                selfieImage: selfiePath,
                livenessImages: livenessImagesPaths,
                apiResponse: apiResponse
            )
        } else if let error = error {
            callback.didError(error: error)
        } else {
            callback.didError(error: SmileIDError.unknown("Unknown error"))
        }
    }

    // MARK: SelfieJobSubmissionDelegate Methods

    func submissionDidSucceed(_ apiResponse: SmartSelfieResponse) {
        DispatchQueue.main.async {
            self.apiResponse = apiResponse
            self.processingState = .success
        }
    }

    func submissionDidFail(
        with error: Error,
        errorMessage: String?,
        errorMessageRes: String?
    ) {
        DispatchQueue.main.async {
            self.error = error
            self.errorMessage = errorMessage
            self.errorMessageRes = errorMessageRes
            self.processingState = .error
        }
    }
}
