import ARKit
import Combine
import Foundation

public protocol SelfieCaptureDelegate {
    func didFinishWith(result: SelfieCaptureResult, error: Error?)
}

// swiftlint:disable opening_brace
public class SelfieViewModel: ObservableObject, ARKitSmileDelegate {
    private let config = SelfieCaptureConfig.defaultConfiguration

    private let isEnroll: Bool
    private let jobId: String
    let allowAgentMode: Bool
    private var localMetadata: LocalMetadata
    private let faceDetector = FaceDetector()
    private var resultDelegate: SelfieCaptureDelegate?

    var cameraManager = CameraManager(orientation: .portrait)
    var shouldAnalyzeImages = true
    var lastAutoCaptureTime = Date()
    var previousHeadRoll = Double.infinity
    var previousHeadPitch = Double.infinity
    var previousHeadYaw = Double.infinity
    var isSmiling = false
    var currentlyUsingArKit: Bool {
        ARFaceTrackingConfiguration.isSupported && !useBackCamera
    }

    var selfieImage: URL?
    var livenessImages: [URL] = []
    var error: Error?

    private let arKitFramePublisher = PassthroughSubject<
        CVPixelBuffer?, Never
    >()
    private var subscribers = Set<AnyCancellable>()

    // UI Properties
    @Published var unauthorizedAlert: AlertState?
    @Published var directive: String = "Instructions.Start"
    /// we use `errorMessageRes` to map to the actual code to the stringRes to allow localization,
    /// and use `errorMessage` to show the actual platform error message that we show if
    /// `errorMessageRes` is not set by the partner
    @Published public var errorMessageRes: String?
    @Published public var errorMessage: String?
    @Published var processingState: ProcessingState?
    @Published var selfieToConfirm: UIImage?
    @Published var captureProgress: Double = 0
    @Published var useBackCamera = false {
        // This is toggled by a Binding
        didSet { switchCamera() }
    }

    public init(
        isEnroll: Bool,
        jobId: String,
        allowAgentMode: Bool = false,
        localMetadata: LocalMetadata = LocalMetadata()
    ) {
        self.isEnroll = isEnroll
        self.jobId = jobId
        self.allowAgentMode = allowAgentMode
        self.localMetadata = localMetadata

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
            .merge(with: arKitFramePublisher)
            .throttle(
                for: 0.35, scheduler: DispatchQueue.global(qos: .userInitiated),
                latest: true
            )
            // Drop the first ~2 seconds to allow the user to settle in
            .dropFirst(5)
            .compactMap { $0 }
            .sink { [weak self] imageBuffer in
                self?.analyzeImage(image: imageBuffer)
            }
            .store(in: &subscribers)

        localMetadata.addMetadata(
            useBackCamera
                ? Metadatum.SelfieImageOrigin(cameraFacing: .backCamera)
                : Metadatum.SelfieImageOrigin(cameraFacing: .frontCamera)
        )
    }

    func configure(delegate: SelfieCaptureDelegate) {
        self.resultDelegate = delegate
    }

    let metadataTimerStart = MonotonicTime()

    func updateLocalMetadata(_ newMetadata: LocalMetadata) {
        localMetadata = newMetadata
        objectWillChange.send()
    }

    // swiftlint:disable cyclomatic_complexity
    func analyzeImage(image: CVPixelBuffer) {
        let elapsedtime = Date().timeIntervalSince(lastAutoCaptureTime)
        if !shouldAnalyzeImages || elapsedtime < config.intraImageMinDelay {
            return
        }

        do {
            try faceDetector.detect(imageBuffer: image) { [weak self] request, error in
                guard let self else { return }
                if let error {
                    print(
                        "Error analyzing image: \(error.localizedDescription)")
                    self.error = error
                    return
                }

                guard let results = request.results as? [VNFaceObservation]
                else {
                    print("Did not receive the expected [VNFaceObservation]")
                    return
                }

                if results.count == 0 {
                    DispatchQueue.main.async {
                        self.directive = "Instructions.UnableToDetectFace"
                    }
                    // If no faces are detected for a while, reset the state
                    if elapsedtime > config.noFaceResetDelay {
                        DispatchQueue.main.async {
                            self.captureProgress = 0
                            self.selfieToConfirm = nil
                            self.processingState = nil
                        }
                        selfieImage = nil
                        livenessImages = []
                        cleanUpSelfieCapture()
                    }
                    return
                }

                // Ensure only 1 face is in frame
                if results.count > 1 {
                    DispatchQueue.main.async {
                        self.directive = "Instructions.MultipleFaces"
                    }
                    return
                }

                guard let face = results.first else {
                    print("Unexpectedly got an empty face array")
                    return
                }

                // The coordinate system of the bounding box in VNFaceObservation is such that
                // the camera view spans [0-1]x[0-1] and the face is within that. Since we don't
                // need to draw on the camera view, we don't need to convert this to the view's
                // coordinate system. We can calculate out of bounds and face area directly on this
                let boundingBox = face.boundingBox

                // Check that the corners of the face bounding box are within frame
                if boundingBox.minX < config.minFaceCenteredThreshold
                    || boundingBox.minY < config.minFaceCenteredThreshold
                    || boundingBox.maxX > config.maxFaceCenteredThreshold
                    || boundingBox.maxY > config.maxFaceCenteredThreshold {
                    DispatchQueue.main.async {
                        self.directive = "Instructions.PutFaceInOval"
                    }
                    return
                }

                // image's area is equal to 1. so (bbox area / image area) == bbox area
                let faceFillRatio = boundingBox.width * boundingBox.height
                if faceFillRatio < config.minFaceAreaThreshold {
                    DispatchQueue.main.async {
                        self.directive = "Instructions.MoveCloser"
                    }
                    return
                }

                if faceFillRatio > config.maxFaceAreaThreshold {
                    DispatchQueue.main.async {
                        self.directive = "Instructions.MoveFarther"
                    }
                    return
                }

                if let quality = face.faceCaptureQuality,
                   quality < config.faceCaptureQualityThreshold {
                    DispatchQueue.main.async {
                        self.directive = "Instructions.Quality"
                    }
                    return
                }

                let userNeedsToSmile =
                livenessImages.count > config.numLivenessImages / 2

                DispatchQueue.main.async {
                    self.directive =
                    userNeedsToSmile
                    ? "Instructions.Smile" : "Instructions.Capturing"
                }

                // TODO: Use mouth deformation as an alternate signal for non-ARKit capture
                if userNeedsToSmile,
                   currentlyUsingArKit,
                   !isSmiling {
                    return
                }

                // Perform the rotation checks *after* changing directive to Capturing -- we don't
                // want to explicitly tell the user to move their head
                if !hasFaceRotatedEnough(face: face) {
                    print(
                        "Not enough face rotation between captures. Waiting...")
                    return
                }

                let orientation =
                currentlyUsingArKit ? CGImagePropertyOrientation.right : .up
                lastAutoCaptureTime = Date()
                do {
                    if livenessImages.count < config.numLivenessImages {
                        guard
                            let imageData =
                                ImageUtils.resizePixelBufferToHeight(
                                    image,
                                    height: config.livenessImageSize,
                                    orientation: orientation
                                )
                        else {
                            throw SmileIDError.unknown(
                                "Error resizing liveness image")
                        }
                        let imageUrl = try LocalStorage.createLivenessFile(
                            jobId: jobId,
                            livenessFile: imageData
                        )
                         livenessImages.append(imageUrl)
                        DispatchQueue.main.async {
                            self.captureProgress =
                            Double(self.livenessImages.count)
                            / Double(self.config.numTotalSteps)
                        }
                    } else {
                        shouldAnalyzeImages = false
                        guard
                            let imageData =
                                ImageUtils.resizePixelBufferToHeight(
                                    image,
                                    height: config.selfieImageSize,
                                    orientation: orientation
                                )
                        else {
                            throw SmileIDError.unknown(
                                "Error resizing selfie image")
                        }
                        let selfieImage = try LocalStorage.createSelfieFile(
                            jobId: jobId,
                            selfieFile: imageData
                        )
                        self.selfieImage = selfieImage
                        DispatchQueue.main.async {
                            self.captureProgress = 1
                            self.selfieToConfirm = UIImage(data: imageData)
                        }
                    }
                } catch {
                    print("Error saving image: \(error.localizedDescription)")
                    self.error = error
                    DispatchQueue.main.async { self.processingState = .error }
                    return
                }
            }
        } catch {
            print("Error analyzing image: \(error.localizedDescription)")
            return
        }
    }

    func hasFaceRotatedEnough(face: VNFaceObservation) -> Bool {
        guard let roll = face.roll?.doubleValue, let yaw = face.yaw?.doubleValue
        else {
            print("Roll and yaw unexpectedly nil")
            return true
        }
        var didPitchChange = false
        if #available(iOS 15, *) {
            if let pitch = face.pitch?.doubleValue {
                didPitchChange =
                abs(pitch - previousHeadPitch) > config.faceRotationThreshold
            }
        }
        let rollDelta = abs(roll - previousHeadRoll)
        let yawDelta = abs(yaw - previousHeadYaw)

        previousHeadRoll = face.roll?.doubleValue ?? Double.infinity
        previousHeadYaw = face.yaw?.doubleValue ?? Double.infinity
        if #available(iOS 15, *) {
            self.previousHeadPitch = face.pitch?.doubleValue ?? Double.infinity
        }

        return didPitchChange || rollDelta > config.faceRollThreshold
        || yawDelta > config.faceRotationThreshold
    }

    func onSmiling(isSmiling: Bool) {
        self.isSmiling = isSmiling
    }

    func onARKitFrame(frame: ARFrame) {
        arKitFramePublisher.send(frame.capturedImage)
    }

    func switchCamera() {
        cameraManager.switchCamera(to: useBackCamera ? .back : .front)
        localMetadata.metadata.removeAllOfType(Metadatum.SelfieImageOrigin.self)
        localMetadata.addMetadata(
            useBackCamera
                ? Metadatum.SelfieImageOrigin(cameraFacing: .backCamera)
                : Metadatum.SelfieImageOrigin(cameraFacing: .frontCamera))
    }

    func handleSelfieRetake() {
        DispatchQueue.main.async {
            self.captureProgress = 0
            self.processingState = nil
            self.selfieToConfirm = nil
        }
        selfieImage = nil
        livenessImages = []
        shouldAnalyzeImages = true
        cleanUpSelfieCapture()
        localMetadata.metadata.removeAllOfType(Metadatum.SelfieImageOrigin.self)
        localMetadata.metadata.removeAllOfType(
            Metadatum.ActiveLivenessType.self)
        localMetadata.metadata.removeAllOfType(
            Metadatum.SelfieCaptureDuration.self)
    }

    func cleanUpSelfieCapture() {
        do {
            try LocalStorage.deleteLivenessAndSelfieFiles(at: [jobId])
        } catch {
            debugPrint(error.localizedDescription)
        }
    }

    func handleDismiss() {}

    func handleConfirmation() {
        guard let selfieImage = selfieImage,
        !livenessImages.isEmpty else {
            return
        }
        self.resultDelegate?
            .didFinishWith(
                result: SelfieCaptureResult(
                    selfieImage: selfieImage,
                    livenessImages: livenessImages
                ),
                error: error
            )
    }

    func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString)
        else { return }
        UIApplication.shared.open(settingsURL)
    }
}
