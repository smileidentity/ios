import ARKit
import Combine
import SwiftUI

public class SelfieViewModelV2: ObservableObject {
    // MARK: Dependencies
    let cameraManager: CameraManager
    var faceDetector: FaceDetectorProtocol
    private var faceValidator: FaceValidatorProtocol
    var livenessCheckManager: LivenessCheckManager
    private var delayTimer: TimerProtocol
    private let dispatchQueue: DispatchQueueType
    private let metadataTimerStart = MonotonicTime()

    // MARK: Private Properties
    private var subscribers = Set<AnyCancellable>()
    private var faceLayoutGuideFrame = CGRect(x: 0, y: 0, width: 250, height: 350)
    private var elapsedGuideAnimationDelay: TimeInterval = 0
    private var currentFrameBuffer: CVPixelBuffer?
    private(set) var selfieImage: UIImage?
    private var selfieImageURL: URL? {
        didSet {
            dispatchQueue.async {
                self.selfieCaptured = self.selfieImage != nil
            }
        }
    }
    private(set) var livenessImages: [URL] = []
    private(set) var hasDetectedValidFace: Bool = false
    private var shouldBeginLivenessChallenge: Bool {
        hasDetectedValidFace && selfieImage != nil && livenessCheckManager.currentTask != nil
    }
    private var shouldSubmitJob: Bool {
        selfieImage != nil && livenessImages.count == numLivenessImages
    }
    private var submissionTask: Task<Void, Error>?
    private(set) var failureReason: FailureReason?
    private(set) var apiResponse: SmartSelfieResponse?
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
    @Published private(set) var selfieCaptureState: SelfieCaptureState = .capturingSelfie

    // MARK: Injected Properties
    let selfieCaptureConfig: SelfieCaptureConfig
    private let onResult: SmartSelfieResultDelegate
    private var localMetadata: LocalMetadata

    init(
        cameraManager: CameraManager = CameraManager(orientation: .portrait),
        faceDetector: FaceDetectorProtocol = FaceDetectorV2(),
        faceValidator: FaceValidatorProtocol = FaceValidator(),
        livenessCheckManager: LivenessCheckManager = LivenessCheckManager(),
        delayTimer: TimerProtocol = RealTimer(),
        dispatchQueue: DispatchQueueType = DispatchQueue.main,
        selfieCaptureConfig: SelfieCaptureConfig,
        onResult: SmartSelfieResultDelegate,
        localMetadata: LocalMetadata
    ) {
        self.cameraManager = cameraManager
        self.faceDetector = faceDetector
        self.faceValidator = faceValidator
        self.livenessCheckManager = livenessCheckManager
        self.delayTimer = delayTimer
        self.dispatchQueue = dispatchQueue
        self.selfieCaptureConfig = selfieCaptureConfig
        self.onResult = onResult
        self.localMetadata = localMetadata
        self.initialSetup()
    }

    deinit {
        stopGuideAnimationDelayTimer()
        submissionTask?.cancel()
        submissionTask = nil
    }

    private func initialSetup() {
        self.faceValidator.delegate = self
        self.faceDetector.resultDelegate = self
        self.livenessCheckManager.delegate = self

        self.faceValidator.setLayoutGuideFrame(with: faceLayoutGuideFrame)
        self.userInstruction = .headInFrame

        livenessCheckManager.$lookUpProgress
            .merge(
                with: livenessCheckManager.$lookRightProgress,
                livenessCheckManager.$lookUpProgress
            )
            .sink { [weak self] _ in
                self?.dispatchQueue.async {
                    self?.resetGuideAnimationDelayTimer()
                }
            }
            .store(in: &subscribers)

        cameraManager.$status
            .receive(on: DispatchQueue.main)
            .filter { $0 == .unauthorized }
            .map { _ in AlertState.cameraUnauthorized }
            .sink { [weak self] alert in self?.unauthorizedAlert = alert }
            .store(in: &subscribers)

        cameraManager.sampleBufferPublisher
            .throttle(
                for: 0.35,
                scheduler: DispatchQueue.global(qos: .userInitiated),
                latest: true
            )
            // Drop the first ~2 seconds to allow the user to settle in
             .dropFirst(5)
            .compactMap { $0 }
            .sink { [weak self] imageBuffer in
                self?.analyzeFrame(imageBuffer: imageBuffer)
            }
            .store(in: &subscribers)
    }

    private func analyzeFrame(imageBuffer: CVPixelBuffer) {
        currentFrameBuffer = imageBuffer
        faceDetector.processImageBuffer(imageBuffer)
        if hasDetectedValidFace && selfieImage == nil {
            HapticManager.shared.notification(type: .success)
            captureSelfieImage(imageBuffer)
            livenessCheckManager.initiateLivenessCheck()
        }
    }

    // MARK: Actions
    func perform(action: SelfieViewModelAction) {
        switch action {
        case let .windowSizeDetected(windowRect, safeAreaInsets):
            handleWindowSizeChanged(toRect: windowRect, edgeInsets: safeAreaInsets)
        case .onViewAppear:
            handleViewAppeared()
        case .jobProcessingDone:
            onFinished(callback: onResult)
        case .retryJobSubmission:
            handleSubmission()
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

        delayTimer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.elapsedGuideAnimationDelay += 1
            if self.elapsedGuideAnimationDelay == self.guideAnimationDelayTime {
                self.showGuideAnimation = true
                self.stopGuideAnimationDelayTimer()
            }
        }
    }

    private func stopGuideAnimationDelayTimer() {
        delayTimer.invalidate()
    }

    private func handleViewAppeared() {
        cameraManager.switchCamera(to: .front)
        resetGuideAnimationDelayTimer()
        resetSelfieCaptureState()
    }

    private func resetSelfieCaptureState() {
        selfieImage = nil
        livenessImages = []
        selfieCaptureState = .capturingSelfie
        failureReason = nil
    }

    private func handleWindowSizeChanged(toRect: CGSize, edgeInsets: EdgeInsets) {
        let topPadding: CGFloat = edgeInsets.top + 100
        faceLayoutGuideFrame = CGRect(
            x: (toRect.width / 2) - faceLayoutGuideFrame.width / 2,
            y: topPadding,
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
            self.selfieImageURL = try LocalStorage.createSelfieFile(
                jobId: selfieCaptureConfig.jobId,
                selfieFile: imageData
            )
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
            let imageUrl = try LocalStorage.createLivenessFile(
                jobId: selfieCaptureConfig.jobId,
                livenessFile: imageData
            )
            livenessImages.append(imageUrl)
        } catch {
            handleError(error)
        }
    }

    private func handleError(_ error: Error) {
        debugPrint(error.localizedDescription)
    }

    private func handleSubmission() {
        dispatchQueue.async {
            self.selfieCaptureState = .processing(.inProgress)
        }
        guard submissionTask == nil else { return }
        submissionTask = Task {
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
        dispatchQueue.async {
            self.publishUserInstruction(.headInFrame)
        }
    }
}

// MARK: FaceValidatorDelegate Methods
extension SelfieViewModelV2: FaceValidatorDelegate {
    func updateValidationResult(_ result: FaceValidationResult) {
        dispatchQueue.async {
            self.faceInBounds = result.faceInBounds
            self.hasDetectedValidFace = result.hasDetectedValidFace
            self.publishUserInstruction(result.userInstruction)
        }
    }
}

// MARK: LivenessCheckManagerDelegate Methods
extension SelfieViewModelV2: LivenessCheckManagerDelegate {
    func didCompleteLivenessTask() {
        HapticManager.shared.notification(type: .success)
        // capture liveness image twice
        guard let imageBuffer = currentFrameBuffer else { return }
        captureLivenessImage(imageBuffer)
        captureLivenessImage(imageBuffer)
    }

    func didCompleteLivenessChallenge() {
        HapticManager.shared.notification(type: .success)
        dispatchQueue.asyncAfter(deadline: .now() + 1) {
            self.cameraManager.pauseSession()
            self.handleSubmission()
        }
    }

    func livenessChallengeTimeout() {
        let remainingImages = numLivenessImages - livenessImages.count
        let count = remainingImages > 0 ? remainingImages : 0
        for _ in 0..<count {
            if let imageBuffer = currentFrameBuffer {
                captureLivenessImage(imageBuffer)
            }
        }

        self.failureReason = .mobileActiveLivenessTimeout
        self.cameraManager.pauseSession()
        handleSubmission()
    }
}

// MARK: Selfie Job Submission
extension SelfieViewModelV2: SelfieSubmissionDelegate {
    public func submitJob() async throws {
        // Add metadata before submission
        addSelfieCaptureDurationMetaData()

        if selfieCaptureConfig.skipApiSubmission {
            // Skip API submission and update processing state to success
            self.selfieCaptureState = .processing(.success)
            return
        }
        // Create an instance of SelfieSubmissionManager to manage the submission process
        let submissionManager = SelfieSubmissionManager(
            selfieCaptureConfig: selfieCaptureConfig,
            numLivenessImages: self.numLivenessImages,
            selfieImageUrl: self.selfieImageURL,
            livenessImages: self.livenessImages,
            localMetadata: self.localMetadata
        )
        submissionManager.delegate = self
        try await submissionManager.submitJob(failureReason: self.failureReason)
    }

    private func addSelfieCaptureDurationMetaData() {
        localMetadata.addMetadata(
            Metadatum.SelfieCaptureDuration(duration: metadataTimerStart.elapsedTime()))
    }

    public func onFinished(callback: SmartSelfieResultDelegate) {
        if let selfieImageURL = selfieImageURL,
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
        HapticManager.shared.notification(type: .success)
        dispatchQueue.async {
            self.apiResponse = apiResponse
            self.selfieCaptureState = .processing(.success)
        }
    }

    func submissionDidFail(
        with error: Error,
        errorMessage: String?,
        errorMessageRes: String?
    ) {
        HapticManager.shared.notification(type: .error)
        dispatchQueue.async {
            self.error = error
            self.errorMessage = errorMessage
            self.errorMessageRes = errorMessageRes
            self.selfieCaptureState = .processing(.error)
        }
    }
}
