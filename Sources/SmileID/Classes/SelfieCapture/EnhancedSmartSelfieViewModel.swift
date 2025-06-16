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
    private var captureDuration = MonotonicTime()
    private let metadata: Metadata = .shared
    private var networkRetries: Int = 0
    private var selfieCaptureRetries: Int = 0

    // MARK: Private Properties

    private var motionDeviceOrientation: UIDeviceOrientation = UIDevice.current
        .orientation
    private var unlockedDeviceOrientation: UIDeviceOrientation {
        UIDevice.current.orientation
    }
    private var currentOrientation: UIDeviceOrientation {
        return motionManager.isDeviceMotionAvailable
            ? motionDeviceOrientation : unlockedDeviceOrientation
    }

    private var faceLayoutGuideFrame = CGRect(
        x: 0, y: 0, width: 250, height: 350
    )
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
    private var hasRecordedOrientationAtCaptureStart = false

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
    private let skipApiSubmission: Bool
    private let extraPartnerParams: [String: String]
    private let onResult: SmartSelfieResultDelegate

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
        skipApiSubmission: Bool,
        extraPartnerParams: [String: String],
        onResult: SmartSelfieResultDelegate
    ) {
        self.isEnroll = isEnroll
        self.userId = userId
        self.allowNewEnroll = allowNewEnroll
        self.skipApiSubmission = skipApiSubmission
        self.extraPartnerParams = extraPartnerParams
        self.onResult = onResult
        initialSetup()
    }

    deinit {
        subscribers.removeAll()
        stopGuideAnimationDelayTimer()
        invalidateSubmissionTask()
        motionManager.stopDeviceMotionUpdates()
    }

    private func initialSetup() {
        faceValidator.delegate = self
        faceDetector.resultDelegate = self
        livenessCheckManager.delegate = self

        faceValidator.setLayoutGuideFrame(with: faceLayoutGuideFrame)

        livenessCheckManager.$lookLeftProgress
            .merge(
                with: livenessCheckManager.$lookRightProgress,
                livenessCheckManager.$lookUpProgress
            )
            .filter { $0 != 0 }
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
        /*
         At the start of the capture, we record the device orientation and start the capture
         duration timer.
         */
        if !hasRecordedOrientationAtCaptureStart {
            metadata.addMetadata(key: .deviceOrientation)
            hasRecordedOrientationAtCaptureStart = true
            captureDuration.startTime()
        }

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
            incrementNetworkRetries()
            selfieCaptureRetries += 1
            handleViewAppeared()
        case .openApplicationSettings:
            openSettings()
        case let .handleError(error):
            handleError(error)
        }
    }

    private func publishUserInstruction(
        _ instruction: SelfieCaptureInstruction?
    ) {
        if userInstruction != instruction {
            userInstruction = instruction
            resetGuideAnimationDelayTimer()
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
            selfieImage = flipImageForPreview(uiImage)
            // we use a userId and not a jobId here
            selfieImageURL = try LocalStorage.createSelfieFile(
                jobId: userId, selfieFile: imageData
            )
        } catch {
            handleError(error)
        }
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
                jobId: userId, livenessFile: imageData
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
        DispatchQueue.main.async {
            self.selfieCaptureState = .processing(.inProgress)
        }
        guard submissionTask == nil else { return }
        if skipApiSubmission {
            DispatchQueue.main.async {
                self.selfieCaptureState = .processing(.success)
                self.onFinished(callback: self.onResult)
            }
            return
        }
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
        if let error {
            onResult.didError(error: error)
        } else {
            onResult.didError(error: SmileIDError.operationCanceled("User cancelled"))
        }
    }
}

// MARK: FaceDetectorResultDelegate Methods

extension EnhancedSmartSelfieViewModel: FaceDetectorResultDelegate {
    func faceDetector(
        _: EnhancedFaceDetector,
        didDetectFace faceGeometry: FaceGeometryData,
        withFaceQuality faceQuality: Float,
        brightness: Int
    ) {
        faceValidator
            .validate(
                faceGeometry: faceGeometry,
                faceQuality: faceQuality,
                brightness: brightness,
                currentLivenessTask: livenessCheckManager.currentTask
            )
        if shouldBeginLivenessChallenge && !isCapturingLivenessImages {
            livenessCheckManager.processFaceGeometry(faceGeometry)
        }
    }

    func faceDetector(
        _: EnhancedFaceDetector, didFailWithError _: Error
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
        /*
        At the end of the capture, we record the device orientation and
        the capture duration
        */
        metadata.addMetadata(key: .deviceOrientation)
        metadata.addMetadata(
            key: .selfieCaptureDuration,
            value: captureDuration.elapsedTime().milliseconds()
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
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

        failureReason = .mobileActiveLivenessTimeout
        cameraManager.pauseSession()
        handleSubmission()
    }
}

// MARK: Selfie Job Submission

extension EnhancedSmartSelfieViewModel: SelfieSubmissionDelegate {
    public func submitJob() async throws {
        // Add metadata before submission
        addSelfieCaptureMetaData()
        let metadata = metadata.collectAllMetadata()
        let submissionManager = SelfieSubmissionManager(
            userId: userId,
            isEnroll: isEnroll,
            numLivenessImages: numLivenessImages,
            allowNewEnroll: allowNewEnroll,
            selfieImageUrl: selfieImageURL,
            livenessImages: livenessImages,
            extraPartnerParams: extraPartnerParams,
            metadata: metadata
        )
        submissionManager.delegate = self
        try await submissionManager.submitJob(failureReason: failureReason)
    }

    public func onFinished(callback: SmartSelfieResultDelegate) {
        Metadata.shared.onStop()
        if let error = self.error {
            callback.didError(error: error)
        } else if let selfieImageURL = selfieImageURL, livenessImages.count == numLivenessImages {
            
            callback.didSucceed(
                selfieImage: selfieImageURL,
                livenessImages: livenessImages,
                apiResponse: apiResponse
            )
        }
    }

    // MARK: SelfieJobSubmissionDelegate Methods

    func submissionDidSucceed(_ apiResponse: SmartSelfieResponse) {
        resetNetworkRetries()
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

// MARK: - Metadata Helpers
extension EnhancedSmartSelfieViewModel {
    private func addSelfieCaptureMetaData() {
        metadata.addMetadata(key: .activeLivenessType, value: LivenessType.headPose.rawValue)
        metadata.addMetadata(
            key: .cameraName, value: cameraManager.cameraName ?? "Unknown Camera Name")
        metadata.addMetadata(key: .selfieCaptureRetries, value: selfieCaptureRetries)
    }

    private func resetSelfieCaptureMetadata() {
        metadata.removeMetadata(key: .selfieCaptureDuration)
        metadata.removeMetadata(key: .activeLivenessType)
        metadata.removeMetadata(key: .deviceOrientation)
        metadata.removeMetadata(key: .deviceMovementDetected)
        hasRecordedOrientationAtCaptureStart = false
    }

    private func incrementNetworkRetries() {
        networkRetries += 1
        Metadata.shared.addMetadata(key: .networkRetries, value: networkRetries)
    }

    private func resetNetworkRetries() {
        networkRetries = 0
        Metadata.shared.removeMetadata(key: .networkRetries)
    }
}
