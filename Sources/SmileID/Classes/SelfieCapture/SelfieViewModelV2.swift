import ARKit
import Combine
import Foundation

public class SelfieViewModelV2: ObservableObject {
    // MARK: Dependencies
    let cameraManager = CameraManager.shared
    let faceDetector = FaceDetectorV2()
    var activeLiveness = LivenessCheckManager()
    private var subscribers = Set<AnyCancellable>()
    var delayTimer: Timer?

    var selfieImage: URL?
    var livenessImages: [URL] = []

    // MARK: Publishers for Vision data
    @Published private(set) var hasDetectedValidFace: Bool
    @Published private(set) var faceDetectedState: FaceDetectionState {
        didSet {
            determineDirective()
        }
    }
    @Published private(set) var faceGeometryState: FaceObservation<FaceGeometryModel> {
        didSet {
            processUpdatedFaceGeometry()
        }
    }
    @Published private(set) var faceQualityState: FaceObservation<FaceQualityModel> {
        didSet {
            processUpdatedFaceQuality()
        }
    }
    @Published private(set) var selfieQualityState: FaceObservation<SelfieQualityModel> {
        didSet {
            processUpdatedSelfieQuality()
        }
    }
    @Published private(set) var isAcceptableBounds: FaceBoundsState {
        didSet {
            calculateDetectedFaceValidity()
        }
    }
    @Published private(set) var isAcceptableFaceQuality: Bool {
        didSet {
            calculateDetectedFaceValidity()
        }
    }
    @Published private(set) var isAcceptableSelfieQuality: Bool {
        didSet {
            calculateDetectedFaceValidity()
        }
    }

    // MARK: Constants
    private let livenessImageSize = 320
    private let selfieImageSize = 640
    private let numLivenessImages = 6
    private let delayTime: TimeInterval = 5

    // MARK: UI Properties
    @Published private(set) var debugEnabled: Bool
    @Published var unauthorizedAlert: AlertState?
    @Published var directive: String = "Instructions.Start"
    @Published private(set) var guideAnimation: CaptureGuideAnimation? {
        didSet {
            resetDelayTimer()
        }
    }
    @Published private(set) var showGuideAnimation: Bool = false
    @Published private(set) var faceQualityValue: Double = 0.0
    @Published private(set) var selfieQualityValue: SelfieQualityModel = .zero
    var faceLayoutGuideFrame = CGRect(x: 0, y: 0, width: 200, height: 300)
    /// This is meant for debug purposes only.
    @Published var showImages: Bool = false
    @Published private(set) var isSubmittingJob: Bool = false
    @Published var elapsedDelay: TimeInterval = 0

    // MARK: Private Properties
    private let isEnroll: Bool
    private let userId: String
    private let jobId: String
    private let allowNewEnroll: Bool
    private let skipApiSubmission: Bool
    private let extraPartnerParams: [String: String]
    private let useStrictMode: Bool

    public init(
        isEnroll: Bool,
        userId: String,
        jobId: String,
        allowNewEnroll: Bool,
        skipApiSubmission: Bool,
        extraPartnerParams: [String: String],
        useStrictMode: Bool
    ) {
        self.isEnroll = isEnroll
        self.userId = userId
        self.jobId = jobId
        self.allowNewEnroll = allowNewEnroll
        self.skipApiSubmission = skipApiSubmission
        self.extraPartnerParams = extraPartnerParams
        self.useStrictMode = useStrictMode

        hasDetectedValidFace = false
        faceDetectedState = .noFaceDetected
        faceGeometryState = .faceNotFound
        faceQualityState = .faceNotFound
        selfieQualityState = .faceNotFound
        isAcceptableBounds = .unknown
        isAcceptableFaceQuality = false
        isAcceptableSelfieQuality = false

        #if DEBUG
            debugEnabled = true
        #else
            debugEnabled = false
        #endif

        self.faceDetector.selfieViewModel = self

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
            .sink(receiveValue: analyzeImage)
            .store(in: &subscribers)
    }

    deinit {
        stopDelayTimer()
    }

    private func analyzeImage(imageBuffer: CVPixelBuffer) {
        faceDetector.detect(imageBuffer)
        if hasDetectedValidFace && selfieImage == nil {
            captureSelfieImage(imageBuffer)
            activeLiveness.initiateLivenessCheck()
        }

        activeLiveness.captureImage = { [weak self] in
            self?.captureLivenessImage(imageBuffer)
        }
    }

    // MARK: Actions
    // swiftlint:disable cyclomatic_complexity
    func perform(action: SelfieViewModelAction) {
        switch action {
        case let .windowSizeDetected(windowRect):
            handleWindowSizeChanged(toRect: windowRect)
        case .noFaceDetected:
            publishNoFaceObserved()
        case let .faceObservationDetected(faceObservation):
            publishFaceObservation(faceObservation)
        case let .faceQualityObservationDetected(faceQualityObservation):
            publishFaceQualityObservation(faceQualityObservation)
        case let .selfieQualityObservationDetected(selfieQualityObservation):
            publishSelfieQualityObservation(selfieQualityObservation)
        case .activeLivenessCompleted:
            if selfieImage != nil && livenessImages.count == numLivenessImages {
                submitJob()
            }
        case .activeLivenessTimeout:
            submitJob(forcedFailure: true)
        case .setupDelayTimer:
            resetDelayTimer()
        case .toggleDebugMode:
            toggleDebugMode()
        case .openApplicationSettings:
            openSettings()
        case let .handleError(error):
            handleError(error)
        }
    }
}

// MARK: Action Handlers
extension SelfieViewModelV2 {
    private func resetDelayTimer() {
        elapsedDelay = 0
        showGuideAnimation = false
        stopDelayTimer()
        delayTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.elapsedDelay += 1
            if self.elapsedDelay == self.delayTime {
                self.showGuideAnimation = true
                self.stopDelayTimer()
            }
        }
    }

    private func stopDelayTimer() {
        delayTimer?.invalidate()
        delayTimer = nil
    }

    private func handleWindowSizeChanged(toRect: CGRect) {
        faceLayoutGuideFrame = CGRect(
            x: toRect.midX - faceLayoutGuideFrame.width / 2,
            y: toRect.midY - faceLayoutGuideFrame.height / 2,
            width: faceLayoutGuideFrame.width,
            height: faceLayoutGuideFrame.height
        )
    }

    private func publishNoFaceObserved() {
        DispatchQueue.main.async { [self] in
            faceDetectedState = .noFaceDetected
            faceGeometryState = .faceNotFound
        }
    }

    private func publishFaceObservation(_ faceGeometryModel: FaceGeometryModel) {
        DispatchQueue.main.async { [self] in
            faceDetectedState = .faceDetected
            faceGeometryState = .faceFound(faceGeometryModel)
        }
    }

    private func publishFaceQualityObservation(_ faceQualityModel: FaceQualityModel) {
        DispatchQueue.main.async { [self] in
            faceDetectedState = .faceDetected
            faceQualityState = .faceFound(faceQualityModel)
        }
    }

    private func publishSelfieQualityObservation(_ selfieQualityModel: SelfieQualityModel) {
        DispatchQueue.main.async { [self] in
            faceDetectedState = .faceDetected
            selfieQualityState = .faceFound(selfieQualityModel)
        }
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
            let selfieImage = try LocalStorage.createSelfieFile(jobId: jobId, selfieFile: imageData)
            self.selfieImage = selfieImage
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

    private func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
    }

    private func toggleDebugMode() {
        debugEnabled.toggle()
    }
}

// MARK: Helpers
extension SelfieViewModelV2 {
    func determineDirective() {
        switch faceDetectedState {
        case .faceDetected:
            if hasDetectedValidFace {
                if let currentLivenessTask = activeLiveness.currentTask {
                    directive = currentLivenessTask.instruction
                    guideAnimation = currentLivenessTask.guideAnimation
                } else {
                    directive = ""
                    guideAnimation = nil
                }
            } else if isAcceptableBounds == .detectedFaceTooSmall {
                directive = "Please bring your face closer to the camera"
                guideAnimation = .moveCloser
            } else if isAcceptableBounds == .detectedFaceTooLarge {
                directive = "Please hold the camera further from your face"
                guideAnimation = .moveBack
            } else if isAcceptableBounds == .detectedFaceOffCentre {
                directive = "Please move your face to the center of the frame"
                guideAnimation = .headInFrame
            } else if !isAcceptableSelfieQuality {
                directive = "Image quality is too low"
                guideAnimation = .goodLight
            }
        case .noFaceDetected:
            if directive != "Please look at the camera" {
                directive = "Please look at the camera"
            }
            if guideAnimation != .headInFrame {
                guideAnimation = .headInFrame
            }
        case .faceDetectionErrored:
            directive = ""
            guideAnimation = nil
            return
        }
    }

    func processUpdatedFaceGeometry() {
        switch faceGeometryState {
        case let .faceFound(faceGeometryModel):
            let boundingBox = faceGeometryModel.boundingBox
            updateAcceptableBounds(using: boundingBox)
            if hasDetectedValidFace && selfieImage != nil && activeLiveness.currentTask != nil {
                activeLiveness.processFaceGeometry(faceGeometryModel)
            }
        case .faceNotFound:
            invalidateFaceGeometryState()
        case let .errored(error):
            print(error.localizedDescription)
            invalidateFaceGeometryState()
        }
    }

    func invalidateFaceGeometryState() {
        // This is where we reset all the face geometry values.
        isAcceptableBounds = .unknown
    }

    func updateAcceptableBounds(using boundingBox: CGRect) {
        if boundingBox.width > 1.2 * faceLayoutGuideFrame.width {
            isAcceptableBounds = .detectedFaceTooLarge
        } else if boundingBox.width * 1.2 < faceLayoutGuideFrame.width {
            isAcceptableBounds = .detectedFaceTooSmall
        } else {
            if abs(boundingBox.midX - faceLayoutGuideFrame.midX) > 50 {
                isAcceptableBounds = .detectedFaceOffCentre
            } else if abs(boundingBox.midY - faceLayoutGuideFrame.midY) > 50 {
                isAcceptableBounds = .detectedFaceOffCentre
            } else {
                isAcceptableBounds = .detectedFaceAppropriateSizeAndPosition
            }
        }
    }

    func processUpdatedFaceQuality() {
        switch faceQualityState {
        case let .faceFound(faceQualityModel):
            // Check acceptable range here.
            isAcceptableFaceQuality = faceQualityModel.quality > 0.2
            faceQualityValue = Double(faceQualityModel.quality)
        case .faceNotFound:
            isAcceptableFaceQuality = false
        case let .errored(error):
            print(error.localizedDescription)
            isAcceptableFaceQuality = false
        }
    }

    func processUpdatedSelfieQuality() {
        switch selfieQualityState {
        case let .faceFound(selfieQualityModel):
            // Check acceptable range here.
            isAcceptableSelfieQuality = selfieQualityModel.passed > 0.5
            selfieQualityValue = selfieQualityModel
        case .faceNotFound:
            isAcceptableSelfieQuality = false
        case let .errored(error):
            print(error.localizedDescription)
            isAcceptableSelfieQuality = false
        }
    }

    func calculateDetectedFaceValidity() {
        hasDetectedValidFace =
            isAcceptableBounds == .detectedFaceAppropriateSizeAndPosition && isAcceptableFaceQuality
            && isAcceptableSelfieQuality
    }
}

// MARK: API Helpers
extension SelfieViewModelV2 {
    func submitJob(forcedFailure: Bool = false) {
        isSubmittingJob = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.isSubmittingJob = false
            self.showImages = true
        }
    }
}
