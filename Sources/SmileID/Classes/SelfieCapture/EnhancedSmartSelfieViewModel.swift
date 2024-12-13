import ARKit
import Combine
import CoreMotion
import SwiftUI

public class EnhancedSmartSelfieViewModel: ObservableObject {
    // MARK: Dependencies
    private let motionManager = CMMotionManager()
    let cameraManager = CameraManager(orientation: .portrait)
    let faceDetector = EnhancedFaceDetector()
    private let faceValidator = FaceValidator()
    var livenessCheckManager = LivenessCheckManager()
    private var subscribers = Set<AnyCancellable>()
    private var guideAnimationDelayTimer: Timer?
    private let metadataTimerStart = MonotonicTime()

    // MARK: Private Properties
    private var motionDeviceOrientation: UIDeviceOrientation = UIDevice.current
        .orientation
    private var unlockedDeviceOrientation: UIDeviceOrientation {
        UIDevice.current.orientation
    }
    private var faceLayoutGuideFrame = CGRect(
        x: 0, y: 0, width: 250, height: 350)
    private var elapsedGuideAnimationDelay: TimeInterval = 0
    private var currentFrameBuffer: CVPixelBuffer?
    var selfieImage: UIImage?
    private var selfieImageURL: URL? {
        didSet {
            DispatchQueue.main.async {
                self.selfieCaptured = self.selfieImage != nil
            }
        }
    }
    private var livenessImages: [URL] = []
    private var hasDetectedValidFace: Bool = false
    private var isCapturingLivenessImages = false
    private var shouldBeginLivenessChallenge: Bool {
        hasDetectedValidFace && selfieImage != nil
            && livenessCheckManager.currentTask != nil
    }
    private var shouldSubmitJob: Bool {
        selfieImage != nil && livenessImages.count == numLivenessImages
    }
    private var submissionTask: Task<Void, Error>?
    private var failureReason: FailureReason?
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
    @Published private(set) var selfieCaptureState: SelfieCaptureState =
        .capturingSelfie

    // MARK: Injected Properties
    private let isEnroll: Bool
    private let userId: String
    private let allowNewEnroll: Bool
    private let extraPartnerParams: [String: String]
    private let onResult: SmartSelfieResultDelegate
    private var localMetadata: LocalMetadata

    enum SelfieCaptureState: Equatable {
        case capturingSelfie
        case processing(ProcessingState)

        var title: String {
            switch self {
            case .capturingSelfie:
                return "Instructions.Capturing"
            case let .processing(processingState):
                return processingState.title
            }
        }
    }

    public init(
        isEnroll: Bool,
        userId: String,
        allowNewEnroll: Bool,
        extraPartnerParams: [String: String],
        onResult: SmartSelfieResultDelegate,
        localMetadata: LocalMetadata
    ) {
        self.isEnroll = isEnroll
        self.userId = userId
        self.allowNewEnroll = allowNewEnroll
        self.extraPartnerParams = extraPartnerParams
        self.onResult = onResult
        self.localMetadata = localMetadata
        self.initialSetup()
    }

    deinit {
        subscribers.removeAll()
        stopGuideAnimationDelayTimer()
        invalidateSubmissionTask()
        motionManager.stopDeviceMotionUpdates()
    }

    private func initialSetup() {
        self.faceValidator.delegate = self
        self.faceDetector.resultDelegate = self
        self.livenessCheckManager.delegate = self

        self.faceValidator.setLayoutGuideFrame(with: faceLayoutGuideFrame)

        livenessCheckManager.$lookLeftProgress
            .merge(
                with: livenessCheckManager.$lookRightProgress,
                livenessCheckManager.$lookUpProgress
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.resetGuideAnimationDelayTimer()
                }
            }
            .store(in: &subscribers)

        if cameraManager.session.canSetSessionPreset(.vga640x480) {
            cameraManager.session.sessionPreset = .vga640x480
        }
        cameraManager.$status
            .receive(on: DispatchQueue.main)
            .filter { $0 == .unauthorized }
            .map { _ in AlertState.cameraUnauthorized }
            .sink { [weak self] alert in self?.unauthorizedAlert = alert }
            .store(in: &subscribers)

        cameraManager.sampleBufferPublisher
            .receive(on: DispatchQueue.main)
            .throttle(
                for: 0.35,
                scheduler: DispatchQueue.global(qos: .userInitiated),
                latest: true
            )
            // Drop the first ~2 seconds to allow the user to settle in
            .dropFirst(5)
            .compactMap { $0 }
            .sink { [weak self] imageBuffer in
                self?.handleCameraImageBuffer(imageBuffer)
            }
            .store(in: &subscribers)

        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(to: OperationQueue()) { [weak self] deviceMotion, _ in
                guard let gravity = deviceMotion?.gravity else { return }
                if abs(gravity.y) < abs(gravity.x) {
                    self?.motionDeviceOrientation =
                        gravity.x > 0 ? .landscapeRight : .landscapeLeft
                } else {
                    self?.motionDeviceOrientation =
                        gravity.y > 0 ? .portraitUpsideDown : .portrait
                }
            }
        }
    }

    private func handleCameraImageBuffer(_ imageBuffer: CVPixelBuffer) {
        let currentOrientation: UIDeviceOrientation =
            motionManager.isDeviceMotionAvailable
            ? motionDeviceOrientation : unlockedDeviceOrientation
        if currentOrientation == .portrait {
            analyzeFrame(imageBuffer: imageBuffer)
        } else {
            DispatchQueue.main.async {
                self.faceInBounds = false
                self.publishUserInstruction(.turnPhoneUp)
            }
        }
    }

    private func analyzeFrame(imageBuffer: CVPixelBuffer) {
        currentFrameBuffer = imageBuffer
        faceDetector.processImageBuffer(imageBuffer)
        if hasDetectedValidFace && selfieImage == nil {
            captureSelfieImage(imageBuffer)
            HapticManager.shared.notification(type: .success)
            livenessCheckManager.initiateLivenessCheck()
        }
    }

    // MARK: Actions
    func perform(action: SelfieViewModelAction) {
        switch action {
        case let .windowSizeDetected(windowRect, safeAreaInsets):
            handleWindowSizeChanged(to: windowRect, edgeInsets: safeAreaInsets)
        case .onViewAppear:
            handleViewAppeared()
        case .cancelSelfieCapture:
            handleCancelSelfieCapture()
        case .retryJobSubmission:
            handleSubmission()
        case .openApplicationSettings:
            openSettings()
        case let .handleError(error):
            handleError(error)
        }
    }

    private func publishUserInstruction(
        _ instruction: SelfieCaptureInstruction?
    ) {
        if self.userInstruction != instruction {
            self.userInstruction = instruction
            self.resetGuideAnimationDelayTimer()
        }
    }
}

// MARK: Action Handlers
extension EnhancedSmartSelfieViewModel {
    private func resetGuideAnimationDelayTimer() {
        elapsedGuideAnimationDelay = 0
        showGuideAnimation = false
        guard guideAnimationDelayTimer == nil else { return }
        guideAnimationDelayTimer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true
        ) { _ in
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
        selfieCaptureState = .capturingSelfie
        failureReason = nil
        resetSelfieCaptureMetadata()
    }

    private func handleWindowSizeChanged(
        to rect: CGSize, edgeInsets: EdgeInsets
    ) {
        let topPadding: CGFloat = edgeInsets.top + 100
        faceLayoutGuideFrame = CGRect(
            x: (rect.width / 2) - faceLayoutGuideFrame.width / 2,
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
                ),
                let uiImage = UIImage(data: imageData)
            else {
                throw SmileIDError.unknown("Error resizing selfie image")
            }
            self.selfieImage = flipImageForPreview(uiImage)
            // we use a userId and not a jobId here
            self.selfieImageURL = try LocalStorage.createSelfieFile(
                jobId: userId, selfieFile: imageData)
        } catch {
            handleError(error)
        }
    }

    private func flipImageForPreview(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let contextSize = CGSize(
            width: image.size.width, height: image.size.height)
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
                width: image.size.width, height: image.size.height)
        )

        // Get the new UIImage from the context
        let correctedImage = UIGraphicsGetImageFromCurrentImageContext()

        return correctedImage
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
            // we use a userId and not a jobId here
            let imageUrl = try LocalStorage.createLivenessFile(
                jobId: userId, livenessFile: imageData)
            livenessImages.append(imageUrl)
        } catch {
            handleError(error)
        }
    }

    private func handleError(_ error: Error) {
        debugPrint(error.localizedDescription)
    }

    private func handleSubmission() {
        DispatchQueue.main.async {
            self.selfieCaptureState = .processing(.inProgress)
        }
        guard submissionTask == nil else { return }
        submissionTask = Task {
            try await submitJob()
        }
    }

    private func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString)
        else { return }
        UIApplication.shared.open(settingsURL)
    }

    private func handleCancelSelfieCapture() {
        invalidateSubmissionTask()
        UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true)
    }

    private func dismissSelfieCapture() {
        UIApplication.shared.windows.first?.rootViewController?.dismiss(
            animated: true,
            completion: { [weak self] in
                guard let self else { return }
                self.onFinished(callback: self.onResult)
            }
        )
    }
}

// MARK: FaceDetectorResultDelegate Methods
extension EnhancedSmartSelfieViewModel: FaceDetectorResultDelegate {
    func faceDetector(
        _ detector: EnhancedFaceDetector,
        didDetectFace faceGeometry: FaceGeometryData,
        withFaceQuality faceQuality: Float,
        brightness: Int
    ) {
        faceValidator
            .validate(
                faceGeometry: faceGeometry,
                faceQuality: faceQuality,
                brightness: brightness,
                currentLivenessTask: self.livenessCheckManager.currentTask
            )
        if shouldBeginLivenessChallenge && !isCapturingLivenessImages {
            livenessCheckManager.processFaceGeometry(faceGeometry)
        }
    }

    func faceDetector(
        _ detector: EnhancedFaceDetector, didFailWithError error: Error
    ) {
        DispatchQueue.main.async {
            self.publishUserInstruction(.headInFrame)
        }
    }
}

// MARK: FaceValidatorDelegate Methods
extension EnhancedSmartSelfieViewModel: FaceValidatorDelegate {
    func updateValidationResult(_ result: FaceValidationResult) {
        DispatchQueue.main.async {
            self.faceInBounds = result.faceInBounds
            self.hasDetectedValidFace = result.hasDetectedValidFace
            self.publishUserInstruction(result.userInstruction)
        }
    }
}

// MARK: LivenessCheckManagerDelegate Methods
extension EnhancedSmartSelfieViewModel: LivenessCheckManagerDelegate {
    func didCompleteLivenessTask() {
        isCapturingLivenessImages = true
        let capturedFrames = 0
        captureNextFrame(capturedFrames: capturedFrames)
    }

    private func captureNextFrame(capturedFrames: Int) {
        let maxFrames = LivenessTask.numberOfFramesToCapture
        guard capturedFrames < maxFrames,
            let currentFrame = currentFrameBuffer
        else {
            return
        }

        captureLivenessImage(currentFrame)
        let nextCapturedFrames = capturedFrames + 1
        if nextCapturedFrames < maxFrames {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.captureNextFrame(capturedFrames: nextCapturedFrames)
            }
        } else {
            isCapturingLivenessImages = false
            HapticManager.shared.notification(type: .success)
        }
    }

    func didCompleteLivenessChallenge() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.cameraManager.pauseSession()
            self.handleSubmission()
        }
    }

    func livenessChallengeTimeout() {
        let remainingImages = numLivenessImages - livenessImages.count
        let count = remainingImages > 0 ? remainingImages : 0
        for _ in 0..<count {
            if let imageBuffer = self.currentFrameBuffer {
                self.captureLivenessImage(imageBuffer)
            }
        }

        self.failureReason = .mobileActiveLivenessTimeout
        self.cameraManager.pauseSession()
        handleSubmission()
    }
}

// MARK: Selfie Job Submission
extension EnhancedSmartSelfieViewModel: SelfieSubmissionDelegate {
    public func submitJob() async throws {
        // Add metadata before submission
        addSelfieCaptureMetaData()

        // Create an instance of SelfieSubmissionManager to manage the submission process
        let submissionManager = SelfieSubmissionManager(
            userId: self.userId,
            isEnroll: self.isEnroll,
            numLivenessImages: self.numLivenessImages,
            allowNewEnroll: self.allowNewEnroll,
            selfieImageUrl: self.selfieImageURL,
            livenessImages: self.livenessImages,
            extraPartnerParams: self.extraPartnerParams,
            localMetadata: self.localMetadata
        )
        submissionManager.delegate = self
        try await submissionManager.submitJob(failureReason: self.failureReason)
    }

    private func addSelfieCaptureMetaData() {
        localMetadata.addMetadata(
            Metadatum.SelfieCaptureDuration(
                duration: metadataTimerStart.elapsedTime())
        )
        localMetadata.addMetadata(
            Metadatum.ActiveLivenessType(livenessType: LivenessType.headPose)
        )
        localMetadata.addMetadata(
            Metadatum(
                name: "camera_name",
                value: cameraManager.cameraName ?? "Unknown Camera Name"
            )
        )
    }

    private func resetSelfieCaptureMetadata() {
        localMetadata.metadata.removeAllOfType(
            Metadatum.SelfieCaptureDuration.self)
        localMetadata.metadata.removeAllOfType(
            Metadatum.ActiveLivenessType.self)
    }

    public func onFinished(callback: SmartSelfieResultDelegate) {
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
            self.dismissSelfieCapture()
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
