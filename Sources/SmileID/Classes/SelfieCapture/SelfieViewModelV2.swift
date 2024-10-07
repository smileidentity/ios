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
    let metadataTimerStart = MonotonicTime()

    // MARK: Private Properties
    private var faceLayoutGuideFrame = CGRect(x: 0, y: 0, width: 200, height: 300)
    private var elapsedGuideAnimationDelay: TimeInterval = 0
    var selfieImage: URL? {
        didSet {
            self.selfieCaptured = self.selfieImage != nil
        }
    }
    var livenessImages: [URL] = []
    private var hasDetectedValidFace: Bool = false
    private var shouldBeginLivenessChallenge: Bool {
        hasDetectedValidFace &&
        selfieImage != nil &&
        livenessCheckManager.currentTask != nil
    }
    private var shouldSubmitJob: Bool {
        selfieImage != nil &&
        livenessImages.count == numLivenessImages
    }
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
    private var localMetadata: LocalMetadata

    public init(
        isEnroll: Bool,
        userId: String,
        jobId: String,
        allowNewEnroll: Bool,
        skipApiSubmission: Bool,
        extraPartnerParams: [String: String],
        useStrictMode: Bool,
        localMetadata: LocalMetadata
    ) {
        self.isEnroll = isEnroll
        self.userId = userId
        self.jobId = jobId
        self.allowNewEnroll = allowNewEnroll
        self.skipApiSubmission = skipApiSubmission
        self.extraPartnerParams = extraPartnerParams
        self.useStrictMode = useStrictMode
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
            if shouldSubmitJob {
                submitJob()
            }
        case .activeLivenessTimeout:
            submitJob(forcedFailure: true)
        case .onViewAppear:
            handleViewAppeared()
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
    
    private func handleViewAppeared() {
        cameraManager.switchCamera(to: .front)
        resetGuideAnimationDelayTimer()
        resetSelfieCaptureState()
    }
    
    private func resetSelfieCaptureState() {
        selfieImage = nil
        livenessImages = []
        processingState = nil
    }

    private func handleWindowSizeChanged(toRect: CGRect) {
        faceLayoutGuideFrame = CGRect(
            x: toRect.midX - faceLayoutGuideFrame.width / 2,
            y: toRect.midY - faceLayoutGuideFrame.height / 2,
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

// MARK: API Helpers
extension SelfieViewModelV2 {
//    func submitJob(forcedFailure: Bool = false) {
//        DispatchQueue.main.async {
//            self.processingState = .inProgress
//            self.showProcessingView = true
//        }
//    }
    
    public func submitJob(forcedFailure: Bool = false) {
        localMetadata.addMetadata(
            Metadatum.SelfieCaptureDuration(duration: metadataTimerStart.elapsedTime()))
        if skipApiSubmission {
            DispatchQueue.main.async { self.processingState = .success }
            return
        }
        DispatchQueue.main.async { self.processingState = .inProgress }
        Task {
            do {
                guard let selfieImage, livenessImages.count == numLivenessImages else {
                    throw SmileIDError.unknown("Selfie capture failed")
                }
                let jobType =
                    isEnroll ? JobType.smartSelfieEnrollment : JobType.smartSelfieAuthentication
                let authRequest = AuthenticationRequest(
                    jobType: jobType,
                    enrollment: isEnroll,
                    jobId: jobId,
                    userId: userId
                )
                if SmileID.allowOfflineMode {
                    try LocalStorage.saveOfflineJob(
                        jobId: jobId,
                        userId: userId,
                        jobType: jobType,
                        enrollment: isEnroll,
                        allowNewEnroll: allowNewEnroll,
                        localMetadata: localMetadata,
                        partnerParams: extraPartnerParams
                    )
                }
                let authResponse = try await SmileID.api.authenticate(request: authRequest)

                var smartSelfieLivenessImages = [MultipartBody]()
                var smartSelfieImage: MultipartBody?
                if let selfie = try? Data(contentsOf: selfieImage),
                    let media = MultipartBody(
                        withImage: selfie,
                        forKey: selfieImage.lastPathComponent,
                        forName: selfieImage.lastPathComponent
                    )
                {
                    smartSelfieImage = media
                }
                if !livenessImages.isEmpty {
                    let livenessImageInfos = livenessImages.compactMap {
                        liveness -> MultipartBody? in
                        if let data = try? Data(contentsOf: liveness) {
                            return MultipartBody(
                                withImage: data,
                                forKey: liveness.lastPathComponent,
                                forName: liveness.lastPathComponent
                            )
                        }
                        return nil
                    }

                    smartSelfieLivenessImages.append(
                        contentsOf: livenessImageInfos.compactMap { $0 })
                }
                guard let smartSelfieImage = smartSelfieImage,
                    smartSelfieLivenessImages.count == numLivenessImages
                else {
                    throw SmileIDError.unknown("Selfie capture failed")
                }

                let response =
                    if isEnroll {
                        try await SmileID.api.doSmartSelfieEnrollment(
                            signature: authResponse.signature,
                            timestamp: authResponse.timestamp,
                            selfieImage: smartSelfieImage,
                            livenessImages: smartSelfieLivenessImages,
                            userId: userId,
                            partnerParams: extraPartnerParams,
                            callbackUrl: SmileID.callbackUrl,
                            sandboxResult: nil,
                            allowNewEnroll: allowNewEnroll,
                            metadata: localMetadata.metadata
                        )
                    } else {
                        try await SmileID.api.doSmartSelfieAuthentication(
                            signature: authResponse.signature,
                            timestamp: authResponse.timestamp,
                            userId: userId,
                            selfieImage: smartSelfieImage,
                            livenessImages: smartSelfieLivenessImages,
                            partnerParams: extraPartnerParams,
                            callbackUrl: SmileID.callbackUrl,
                            sandboxResult: nil,
                            metadata: localMetadata.metadata
                        )
                    }
                apiResponse = response
                do {
                    try LocalStorage.moveToSubmittedJobs(jobId: self.jobId)
                    self.selfieImage = try LocalStorage.getFileByType(
                        jobId: jobId,
                        fileType: FileType.selfie,
                        submitted: true
                    )
                    self.livenessImages =
                        try LocalStorage.getFilesByType(
                            jobId: jobId,
                            fileType: FileType.liveness,
                            submitted: true
                        ) ?? []
                } catch {
                    print("Error moving job to submitted directory: \(error)")
                    self.error = error
                }
                DispatchQueue.main.async { self.processingState = .success }
            } catch let error as SmileIDError {
                do {
                    let didMove = try LocalStorage.handleOfflineJobFailure(
                        jobId: self.jobId,
                        error: error
                    )
                    if didMove {
                        self.selfieImage = try LocalStorage.getFileByType(
                            jobId: jobId,
                            fileType: FileType.selfie,
                            submitted: true
                        )
                        self.livenessImages =
                            try LocalStorage.getFilesByType(
                                jobId: jobId,
                                fileType: FileType.liveness,
                                submitted: true
                            ) ?? []
                    }
                } catch {
                    print("Error moving job to submitted directory: \(error)")
                    self.error = error
                    return
                }
                if SmileID.allowOfflineMode, LocalStorage.isNetworkFailure(error: error) {
                    DispatchQueue.main.async {
                        self.errorMessageRes = "Offline.Message"
                        self.processingState = .success
                    }
                } else {
                    print("Error submitting job: \(error)")
                    let (errorMessageRes, errorMessage) = toErrorMessage(error: error)
                    self.error = error
                    self.errorMessageRes = errorMessageRes
                    self.errorMessage = errorMessage
                    DispatchQueue.main.async { self.processingState = .error }
                }
            } catch {
                print("Error submitting job: \(error)")
                self.error = error
                DispatchQueue.main.async { self.processingState = .error }
            }
        }
    }

    public func onFinished(callback: SmartSelfieResultDelegate) {
        if let selfieImage = selfieImage,
            let selfiePath = getRelativePath(from: selfieImage),
            livenessImages.count == numLivenessImages,
            !livenessImages.contains(where: { getRelativePath(from: $0) == nil })
        {
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
}
