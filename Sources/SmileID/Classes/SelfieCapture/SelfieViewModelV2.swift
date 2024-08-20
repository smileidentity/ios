import ARKit
import Combine
import Foundation

public class SelfieViewModelV2: ObservableObject {
    // MARK: Publishers
    @Published private(set) var debugEnabled: Bool
    @Published var unauthorizedAlert: AlertState?
    @Published var directive: String = "Instructions.Start"

    // MARK: Publishers for Vision data
    @Published private(set) var isFaceInFrame: Bool
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
            calculateFaceValidity()
        }
    }

    // MARK: Dependencies
    var cameraManager = CameraManager(orientation: .portrait)
    var faceDetector = FaceDetectorV2()

    private var subscribers = Set<AnyCancellable>()

    // MARK: UI Properties
    let maxFaceYawThreshold: Double = 15
    let maxFaceRollThreshold: Double = 15
    let maxFacePitchThreshold: Double = 15
    @Published private(set) var yawValue: Double = 0.0
    @Published private(set) var rollValue: Double = 0.0
    @Published private(set) var pitchValue: Double = 0.0
    @Published private(set) var faceDirection: FaceDirection = .none
    @Published private(set) var faceQualityValue: Double = 0.0
    @Published private(set) var selfieQualityValue: SelfieQualityModel = .zero

    // MARK: Private Properties
    private let isEnroll: Bool
    private let userId: String
    private let jobId: String
    private let allowNewEnroll: Bool
    private let skipApiSubmission: Bool
    private let extraPartnerParams: [String: String]
    private let useStrictMode: Bool

    var faceLayoutGuideFrame = CGRect(x: 0, y: 0, width: 200, height: 300)

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

        isFaceInFrame = false
        faceDetectedState = .noFaceDetected
        faceGeometryState = .faceNotFound
        faceQualityState = .faceNotFound
        selfieQualityState = .faceNotFound
        isAcceptableBounds = .unknown

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
            .throttle(for: 0.35, scheduler: DispatchQueue.global(qos: .userInitiated), latest: true)
            .dropFirst(5)
            .compactMap { $0 }
            .sink(receiveValue: analyzeImage)
            .store(in: &subscribers)
    }

    private func analyzeImage(image: CVPixelBuffer) {
        faceDetector.detect(imageBuffer: image)
    }

    // MARK: Actions
    func perform(action: SelfieViewModelAction) {
        switch action {
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
            print(error.localizedDescription)
        }
    }

    // MARK: Action Handlers
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
            faceQualityValue = Double(faceQualityModel.quality)
        case .faceNotFound:
            return
        case let .errored(error):
            print(error.localizedDescription)
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
    
    func calculateFaceValidity() {
        isFaceInFrame = isAcceptableBounds == .detectedFaceAppropriateSizeAndPosition
    }
}
