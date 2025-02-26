import ARKit
import Combine
import CoreMotion
import SwiftUI

public class EnhancedSmartSelfieViewModel: ObservableObject {
    private let config = SelfieCaptureConfig.enhancedConfiguration

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
    private weak var resultDelegate: SelfieCaptureDelegate?

    private var motionDeviceOrientation: UIDeviceOrientation = UIDevice.current
        .orientation
    private var unlockedDeviceOrientation: UIDeviceOrientation {
        UIDevice.current.orientation
    }

    private var faceLayoutGuideFrame = CGRect(
        x: 0, y: 0, width: 250, height: 350
    )
    private var elapsedGuideAnimationDelay: TimeInterval = 0
    private var currentFrameBuffer: CVPixelBuffer?
    private var selfieImageURL: URL? {
        didSet {
            DispatchQueue.main.async {
                self.selfieCaptured = self.selfieImageURL != nil
            }
        }
    }

    private var livenessImages: [URL] = []
    private var hasDetectedValidFace: Bool = false
    private var isCapturingLivenessImages = false
    private var shouldBeginLivenessChallenge: Bool {
        hasDetectedValidFace && selfieImageURL != nil
            && livenessCheckManager.currentTask != nil
    }

    private var shouldSubmitJob: Bool {
        selfieImageURL != nil && livenessImages.count == config.numLivenessImages
    }
    private var failureReason: FailureReason?

    // MARK: UI Properties

    @Published var unauthorizedAlert: AlertState?
    @Published private(set) var userInstruction: SelfieCaptureInstruction?
    @Published private(set) var faceInBounds: Bool = false
    @Published private(set) var selfieCaptured: Bool = false
    @Published private(set) var showGuideAnimation: Bool = false

    // MARK: Injected Properties

    private let userId: String
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
        userId: String,
        localMetadata: LocalMetadata = LocalMetadata()
    ) {
        self.userId = userId
        self.localMetadata = localMetadata
        initialSetup()
    }

    deinit {
        subscribers.removeAll()
        stopGuideAnimationDelayTimer()
        motionManager.stopDeviceMotionUpdates()
    }

    func configure(delegate: SelfieCaptureDelegate) {
        self.resultDelegate = delegate
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
        if hasDetectedValidFace && selfieImageURL == nil {
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
            if self.elapsedGuideAnimationDelay == self.config.guideAnimationDelayTime {
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
        selfieImageURL = nil
        livenessImages = []
        failureReason = nil
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
                    height: config.selfieImageSize,
                    orientation: .up
                )
            else {
                throw SmileIDError.unknown("Error resizing selfie image")
            }
            // we use a userId and not a jobId here
            selfieImageURL = try LocalStorage.createSelfieFile(
                jobId: userId, selfieFile: imageData
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
                    height: config.livenessImageSize,
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

    private func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString)
        else { return }
        UIApplication.shared.open(settingsURL)
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
        _: EnhancedFaceDetector, didFailWithError error: Error
    ) {
        DispatchQueue.main.async {
            print("Enhanced Face Detector Error:", error.localizedDescription)
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.cameraManager.pauseSession()
            self?.onFinish()
        }
    }

    func livenessChallengeTimeout() {
        let remainingImages = config.numLivenessImages - livenessImages.count
        let count = remainingImages > 0 ? remainingImages : 0
        for _ in 0 ..< count {
            if let imageBuffer = currentFrameBuffer {
                captureLivenessImage(imageBuffer)
            }
        }

        failureReason = .mobileActiveLivenessTimeout
        cameraManager.pauseSession()
        onFinish()
    }

    func onFinish() {
        guard let selfieImageURL = selfieImageURL,
              livenessImages.count == config.numLivenessImages,
              !livenessImages.contains(where: { getRelativePath(from: $0) == nil }) else {
            self.resultDelegate?.didFinish(with: SmileIDError.selfieCaptureFailed)
            return
        }

        // Add metadata before submission
        addSelfieCaptureMetaData()

        let livenessImagesPaths = livenessImages.compactMap { $0 }

        self.resultDelegate?
            .didFinish(
                with: SelfieCaptureResult(
                    selfieImage: selfieImageURL,
                    livenessImages: livenessImagesPaths
                ),
                failureReason: self.failureReason
            )
    }
}
