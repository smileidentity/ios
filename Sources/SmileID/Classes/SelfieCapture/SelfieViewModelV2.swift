import ARKit
import Combine
import Foundation

public class SelfieViewModelV2: ObservableObject {
    // MARK: Dependencies
    var cameraManager = CameraManager.shared
    var faceDetector = FaceDetectorV2()
    private var subscribers = Set<AnyCancellable>()

    var selfieImage: URL?
    var livenessImages: [URL] = []

    // MARK: Publishers
    @Published private(set) var debugEnabled: Bool
    @Published var unauthorizedAlert: AlertState?
    @Published var directive: String = "Instructions.Start"

    // MARK: Publishers for Vision data
    @Published private(set) var hasDetectedValidFace: Bool
    @Published private(set) var hasCompletedLivenessChallenge: Bool
    @Published private(set) var faceDetectedState: FaceDetectionState
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
    @Published private(set) var isAcceptableQuality: Bool {
        didSet {
            calculateDetectedFaceValidity()
        }
    }
    @Published private(set) var boundingXDelta: CGFloat = .zero
    @Published private(set) var boundingYDelta: CGFloat = .zero

    // MARK: Constants
    private let maxFaceYawThreshold: Double = 15
    private let maxFaceRollThreshold: Double = 15
    private let maxFacePitchThreshold: Double = 15
    private let livenessImageSize = 320
    private let selfieImageSize = 640

    // MARK: UI Properties
    @Published private(set) var yawValue: Double = 0.0
    @Published private(set) var rollValue: Double = 0.0
    @Published private(set) var pitchValue: Double = 0.0
    @Published private(set) var faceDirection: FaceDirection = .none
    @Published private(set) var faceQualityValue: Double = 0.0
    @Published private(set) var selfieQualityValue: SelfieQualityModel = .zero
    var faceLayoutGuideFrame = CGRect(x: 0, y: 0, width: 200, height: 300)

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
        hasCompletedLivenessChallenge = false
        faceDetectedState = .noFaceDetected
        faceGeometryState = .faceNotFound
        faceQualityState = .faceNotFound
        selfieQualityState = .faceNotFound
        isAcceptableBounds = .unknown
        isAcceptableQuality = false

        #if DEBUG
            debugEnabled = true
        #else
            debugEnabled = false
        #endif

        self.faceDetector.model = self

        cameraManager.$status
            .receive(on: DispatchQueue.main)
            .filter { $0 == .unauthorized }
            .map { _ in AlertState.cameraUnauthorized }
            .sink { alert in self.unauthorizedAlert = alert }
            .store(in: &subscribers)

        cameraManager.sampleBufferPublisher
            .compactMap { $0 }
            .sink(receiveValue: analyzeImage)
            .store(in: &subscribers)
    }

    private func analyzeImage(imageBuffer: CVPixelBuffer) {
        faceDetector.detect(imageBuffer)
        if hasDetectedValidFace && selfieImage == nil {
            captureSelfieImage(imageBuffer)
        }
        // TODO: Confirm this logic with Kwame
        // How many images do we capture and
        // at what points do we capture those images
        if hasCompletedLivenessChallenge { // should check for each challenge.
            captureLivenessImage(imageBuffer)
        }
    }

    // MARK: Actions
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
        case .toggleDebugMode:
            toggleDebugMode()
        case .openApplicationSettings:
            openSettings()
        case let .handleError(error):
            handleError(error)
        }
    }

    // MARK: Action Handlers
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
            guard let imageData = ImageUtils.resizePixelBufferToHeight(
                pixelBuffer,
                height: selfieImageSize,
                orientation: .up
            ) else {
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
            guard let imageData = ImageUtils.resizePixelBufferToHeight(
                pixelBuffer,
                height: livenessImageSize,
                orientation: .up
            ) else {
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
    func processUpdatedFaceGeometry() {
        switch faceGeometryState {
        case let .faceFound(faceGeometryModel):
            updateFaceGeometryValues(using: faceGeometryModel)

            let boundingBox = faceGeometryModel.boundingBox
            updateAcceptableBounds(using: boundingBox)
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

    func updateFaceGeometryValues(using value: FaceGeometryModel) {
        rollValue = value.roll.doubleValue
        pitchValue = value.pitch.doubleValue
        yawValue = value.yaw.doubleValue
        faceDirection = value.direction
    }

    func updateAcceptableBounds(using boundingBox: CGRect) {
        boundingXDelta = abs(boundingBox.midX - faceLayoutGuideFrame.midX)
        boundingYDelta = abs(boundingBox.midY - faceLayoutGuideFrame.midY)

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
            isAcceptableQuality = faceQualityModel.quality > 0.2
            faceQualityValue = Double(faceQualityModel.quality)
        case .faceNotFound:
            isAcceptableQuality = false
        case let .errored(error):
            print(error.localizedDescription)
            isAcceptableQuality = false
        }
    }

    func processUpdatedSelfieQuality() {
        switch selfieQualityState {
        case let .faceFound(selfieQualityModel):
            // Check acceptable range here.
            selfieQualityValue = selfieQualityModel
        case .faceNotFound:
            return
        case let .errored(error):
            print(error.localizedDescription)
        }
    }

    func calculateDetectedFaceValidity() {
        hasDetectedValidFace =
        isAcceptableBounds == .detectedFaceAppropriateSizeAndPosition &&
        isAcceptableQuality
    }
    
    func calculateActiveLivenessValidity() {
        // hasCompletedLivenessChallenge = true
       // lookLeftChallengeCompleted &&
       // lookRightChallengeCompleted &&
       // pitchChallengeCompleted
    }
}
