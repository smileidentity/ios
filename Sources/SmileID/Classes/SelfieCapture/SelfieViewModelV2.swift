import ARKit
import Combine
import Foundation

public class SelfieViewModelV2: ObservableObject {
    // MARK: Dependencies
    let cameraManager = CameraManager.shared
    let faceDetector = FaceDetectorV2()
    var faceValidator = FaceValidator()
    var activeLiveness = LivenessCheckManager()
    private var subscribers = Set<AnyCancellable>()
    private var guideAnimationDelayTimer: Timer?

    var selfieImage: URL?
    var livenessImages: [URL] = []

    // MARK: Constants
    private let livenessImageSize = 320
    private let selfieImageSize = 640
    private let numLivenessImages = 6
    private let guideAnimationDelayTime: TimeInterval = 5

    // MARK: UI Properties
    @Published private(set) var debugEnabled: Bool
    @Published var unauthorizedAlert: AlertState?
    @Published private(set) var userInstruction: SelfieCaptureInstruction?
    @Published private(set) var showGuideAnimation: Bool = false
    @Published private(set) var faceQualityValue: Double = 0.0
    @Published private(set) var selfieQualityValue: SelfieQualityModel = .zero
    var faceLayoutGuideFrame = CGRect(x: 0, y: 0, width: 200, height: 300)
    @Published private(set) var isSubmittingJob: Bool = false
    @Published var elapsedGuideAnimationDelay: TimeInterval = 0
    /// This is meant for debug purposes only.
    @Published var showImages: Bool = false

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
        stopGuideAnimationDelayTimer()
    }

    private func analyzeImage(imageBuffer: CVPixelBuffer) {
        faceDetector.detect(imageBuffer)
        if faceValidator.hasDetectedValidFace && selfieImage == nil {
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
        case let .updateUserInstruction(instruction):
            publishUserInstruction(instruction)
        case let .faceObservationDetected(faceObservation):
            handleFaceObservation(faceObservation)
        case let .faceQualityObservationDetected(faceQualityObservation):
            handleFaceQualityResult(.faceFound(faceQualityObservation))
        case let .selfieQualityObservationDetected(selfieQualityObservation):
            handleSelfieQualityResult(.faceFound(selfieQualityObservation))
        case .activeLivenessCompleted:
            if selfieImage != nil && livenessImages.count == numLivenessImages {
                submitJob()
            }
        case .activeLivenessTimeout:
            submitJob(forcedFailure: true)
        case .setupDelayTimer:
            resetGuideAnimationDelayTimer()
        case .toggleDebugMode:
            toggleDebugMode()
        case .openApplicationSettings:
            openSettings()
        case let .handleError(error):
            handleError(error)
        }
    }
    
    private func handleFaceObservation(_ faceGeometryModel: FaceGeometryModel) {
        faceValidator.processUpdatedFaceGeometry()
        if faceValidator.hasDetectedValidFace && selfieImage != nil && activeLiveness.currentTask != nil {
            activeLiveness.processFaceGeometry(faceGeometryModel)
        }
    }
    
    private func handleFaceQualityResult(_ faceGeometry: FaceObservation<FaceQualityModel>) {
        faceValidator.processUpdatedFaceQuality()
    }
    
    private func handleSelfieQualityResult(_ faceGeometry: FaceObservation<SelfieQualityModel>) {
        faceValidator.processUpdatedSelfieQuality()
    }
    
    private func publishUserInstruction(_ instruction: SelfieCaptureInstruction?) {
        DispatchQueue.main.async {
            if self.userInstruction != instruction {
                self.userInstruction = instruction
            }
            self.resetGuideAnimationDelayTimer()
        }
    }
}

// MARK: Action Handlers
extension SelfieViewModelV2 {
    private func resetGuideAnimationDelayTimer() {
        elapsedGuideAnimationDelay = 0
        showGuideAnimation = false
        stopGuideAnimationDelayTimer()
        guideAnimationDelayTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.elapsedGuideAnimationDelay += 1
            if self.elapsedGuideAnimationDelay == self.guideAnimationDelayTime {
                self.showGuideAnimation = true
                self.stopGuideAnimationDelayTimer()
            }
        }
    }

    private func stopGuideAnimationDelayTimer() {
        guideAnimationDelayTimer?.invalidate()
        guideAnimationDelayTimer = nil
    }

    private func handleWindowSizeChanged(toRect: CGRect) {
        faceLayoutGuideFrame = CGRect(
            x: toRect.midX - faceLayoutGuideFrame.width / 2,
            y: toRect.midY - faceLayoutGuideFrame.height / 2,
            width: faceLayoutGuideFrame.width,
            height: faceLayoutGuideFrame.height
        )
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

extension SelfieViewModelV2: FaceValidatorDelegate {
    func updateInstruction(_ instruction: SelfieCaptureInstruction?) {
        if self.userInstruction != instruction {
            self.userInstruction = instruction
            resetGuideAnimationDelayTimer()
        }
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
