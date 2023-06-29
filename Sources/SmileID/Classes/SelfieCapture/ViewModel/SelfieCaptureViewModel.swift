import Foundation
import ARKit
import UIKit
import Combine

protocol SelfieViewDelegate {
    func pauseARSession()
    func resumeARSession()
}

enum SelfieCaptureViewModelAction {
    case sceneUnstable
    case noFaceDetected
    case smileDirective
    case smileAction
    case noSmile
    case multipleFacesDetected
    case faceObservationDetected(FaceGeometryModel)
    case faceQualityObservationDetected(FaceQualityModel)
}

enum ProcessingState {
    static func == (lhs: ProcessingState, rhs: ProcessingState) -> Bool {
        switch (lhs, rhs) {
        case (let .complete(response1, error1), let .complete(response2, error2)):
            return false
        case (let .error(error1), let .error(error2)):
            return error1.localizedDescription == error2.localizedDescription
        case (.confirmation, .confirmation):
            return true
        case (.endFlow, .endFlow):
            return true
        case (.inProgress, .inProgress):
            return true
        default:
            return false
        }
    }

    case confirmation
    case inProgress
    case complete(JobStatusResponse?, SmileIDError?)
    case endFlow
    case error(Error)
}

final class SelfieCaptureViewModel: ObservableObject {
    var userId: String
    var jobId: String
    var isEnroll: Bool
    var showAttribution: Bool
    var faceLayoutGuideFrame = CGRect.zero
    var viewFinderSize = CGSize.zero
    let subject = PassthroughSubject<String, Never>()
    lazy var cameraManager = CameraManager()
    private var faceDetector = FaceDetector()
    private var subscribers = Set<AnyCancellable>()
    private var facedetectionSubscribers: AnyCancellable?
    private var throttleSubscription: AnyCancellable?
    private let numberOfLivenessImages = 7
    private let selfieImageSize = CGSize(width: 320, height: 320)
    private var currentBuffer: CVPixelBuffer?
    private var files = [URL]()
    var selfieImage: Data?
    private var livenessImages = [Data]()
    private var lastCaptureTime: Int64 = 0
    private var interCaptureDelay = 600
    weak var captureResultDelegate: SmartSelfieResultDelegate?
    var selfieViewDelegate: SelfieViewDelegate?
    private var debounceTimer: Timer?
    var displayedImage: Data?
    var currentExif: [String: Any]?
    var isARSupported: Bool {
        return ARFaceTrackingConfiguration.isSupported
    }
    @Published var agentMode = false {
        didSet {
            if isARSupported {
                switchARKitCamera()
            } else {
                switchAVCaptureCamera()
            }
        }
    }
    @Published private(set) var progress: CGFloat = 0
    @Published var directive: String = "Instructions.Start"
    @Published private(set) var processingState: ProcessingState?
    {
        didSet {
            switch processingState {
            case .none:
                resumeCameraSession()
            case .endFlow:
                pauseCameraSession()
            case .some:
                pauseCameraSession()
            }
        }
    }

    func pauseCameraSession() {
        if isARSupported && agentMode {
            cameraManager.pauseSession()
        } else if isARSupported && !agentMode {
            selfieViewDelegate?.pauseARSession()
            cameraManager.pauseSession()
        } else if !isARSupported {
            cameraManager.pauseSession()
        }
    }

    func resumeCameraSession() {
        if isARSupported && agentMode {
            cameraManager.resumeSession()
        } else if isARSupported && !agentMode {
            selfieViewDelegate?.resumeARSession()
        } else if !isARSupported {
            cameraManager.resumeSession()
        }
    }

    weak var viewDelegate: FaceDetectorDelegate? {
        didSet {
            faceDetector.viewDelegate = viewDelegate
        }
    }
    var fallbackTimer: Timer?

    private(set) var hasDetectedValidFace: Bool {
        didSet {
            if hasDetectedValidFace {
                if livenessImages.count == 3 && isARSupported && !agentMode {
                    perform(action: .smileDirective)
                    if isSmiling {
                        captureImage()
                        return
                    } else {
                        return
                    }
                } else if livenessImages.count == 3 {
                    self.perform(action: .smileDirective)
                    fallbackTimer = Timer.scheduledTimer(timeInterval: 3,
                                                         target: self,
                                                         selector: #selector(captureImageAfterThreeSecs),
                                                         userInfo: nil,
                                                         repeats: false)
                    return
                }
                captureImage()
            }
        }
    }
    private(set) var isAcceptableRoll: Bool {
        didSet {
            calculateDetectedFaceValidity()
        }
    }
    private(set) var isAcceptableYaw: Bool {
        didSet {
            calculateDetectedFaceValidity()
        }
    }
    private(set) var isAcceptableBounds: FaceBoundsState {
        didSet {
            calculateDetectedFaceValidity()
        }
    }
    private(set) var isAcceptableQuality: Bool = true {
        didSet {
            calculateDetectedFaceValidity()
        }
    }

    private(set) var faceDetectionState: FaceDetectionState
    private(set) var faceGeometryState: FaceObservation<FaceGeometryModel, ErrorWrapper> {
        didSet {
            processUpdatedFaceGeometry()
        }
    }
    private(set) var faceQualityState: FaceObservation<FaceQualityModel, ErrorWrapper> {
        didSet {
            processUpdatedFaceQuality()
        }
    }

    private var isSmiling = false {
        didSet {
            calculateDetectedFaceValidity()
        }
    }

    init(userId: String, jobId: String, isEnroll: Bool, showAttribution: Bool = true) {
        self.userId = userId
        self.isEnroll = isEnroll
        self.jobId = jobId
        self.showAttribution = showAttribution
        faceDetectionState = .noFaceDetected
        isAcceptableRoll = false
        isAcceptableYaw = false
        isAcceptableBounds = .unknown
        isAcceptableQuality = true
        hasDetectedValidFace = false
        faceGeometryState = .faceNotFound
        faceQualityState = .faceNotFound
        faceDetector.model = self
        if ARFaceTrackingConfiguration.isSupported {
            subscribeToARFrame()
        } else {
            setupFaceDetectionSubscriptions()
        }
        setupDirectiveSubscription()
    }

    @objc func captureImageAfterThreeSecs() {
        captureImage()
    }

    func subscribeToARFrame() {
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveFrame),
                                               name: NSNotification.Name(rawValue: "UpdateARFrame"),
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        throttleSubscription?.cancel()
        throttleSubscription = nil
        pauseCameraSession()
    }

    @objc func didReceiveFrame(_ notification: NSNotification) {
        if let dict =  notification.userInfo as? NSDictionary {
            if let frame = dict["frame"] as? ARFrame {
                self.currentBuffer = frame.capturedImage

                if #available(iOS 16.0, *) {
                    self.currentExif = frame.exifData
                } else {
                    self.currentExif = nil
                }
            }
        }
    }

    private func setupFaceDetectionSubscriptions() {
        facedetectionSubscribers = cameraManager.$sampleBuffer
            .receive(on: DispatchQueue.global())
            .compactMap { return $0 }
            .sink {
                self.faceDetector.detect(pixelBuffer: $0)
                self.currentBuffer = $0
            }
    }

    private func pauseFaceDetection() {
        facedetectionSubscribers?.cancel()
        facedetectionSubscribers = nil
        cameraManager.pauseSession()
    }

    func switchARKitCamera() {
        resetCapture()
        facedetectionSubscribers?.cancel()
        facedetectionSubscribers = nil
        if agentMode {
            selfieViewDelegate?.pauseARSession()
            setupFaceDetectionSubscriptions()
            cameraManager.switchCamera(to: .back)
        } else {
            cameraManager.pauseSession()
            selfieViewDelegate?.resumeARSession()
        }
    }

    func handleRetakeButtonTap() {
        resetCapture()
        resumeCameraSession()
    }

    func switchAVCaptureCamera() {
        facedetectionSubscribers?.cancel()
        facedetectionSubscribers = nil
        setupFaceDetectionSubscriptions()
        if agentMode {
            cameraManager.switchCamera(to: .back)
        } else {
            cameraManager.switchCamera(to: .front)
        }
    }

    func perform(action: SelfieCaptureViewModelAction) {
        switch action {
        case .sceneUnstable:
            publishUnstableSceneObserved()
            subject.send("Instructions.Start")
        case .noFaceDetected:
            publishNoFaceObserved()
            subject.send("Instructions.Start")
        case .multipleFacesDetected:
            publishFaceObservation(.multipleFacesDetected)
            subject.send("Instructions.MultipleFaces")
        case .faceObservationDetected(let faceGeometry):
            publishFaceObservation(.faceDetected, faceGeometryModel: faceGeometry)
        case .faceQualityObservationDetected(let faceQualityModel):
            publishFaceObservation(.faceDetected, faceQualityModel: faceQualityModel)
        case .smileDirective:
            subject.send("Instructions.Smile")
        case .smileAction:
            isSmiling = true
        case .noSmile:
            isSmiling = false
        }
    }

    private func captureImage() {
        DispatchQueue.main.async {
            if self.livenessImages.count >= 3 {
                self.perform(action: .smileDirective)
            } else {
                self.subject.send("Instructions.Capturing")
            }
        }
        guard let currentBuffer = currentBuffer, hasDetectedValidFace == true,
              livenessImages.count < numberOfLivenessImages + 1  else {
            return
        }
        guard case let .faceFound(faceGeometry) = faceGeometryState else {
            return
        }
        while (livenessImages.count < numberOfLivenessImages) &&
                ((Date().millisecondsSince1970 - lastCaptureTime) > interCaptureDelay) {
            guard let image = ImageUtils.resizePixelBufferToWidth(currentBuffer, width: 350, exif:
                                                                    currentExif) else { return }
            livenessImages.append(image)
            lastCaptureTime = Date().millisecondsSince1970
            updateProgress()
        }

        if (livenessImages.count == numberOfLivenessImages) &&
            ((Date().millisecondsSince1970 - lastCaptureTime) > interCaptureDelay) &&
            selfieImage == nil {
            publishFaceObservation(.finalFrame)
            guard let displayedImage = ImageUtils.captureFace(from: currentBuffer,
                                                              faceGeometry: faceGeometry,
                                                              agentMode: agentMode,
                                                              finalSize: selfieImageSize,
                                                              screenImageSize: viewFinderSize,
                                                              isSelfie: false) else { return }
            guard let selfieImage = ImageUtils.resizePixelBufferToWidth(currentBuffer, width: 600,
                                                                        exif: currentExif) else { return }
            lastCaptureTime = Date().millisecondsSince1970
            self.selfieImage = selfieImage
            self.displayedImage = displayedImage
            updateProgress()
            do {
                files = try LocalStorage.saveImageJpg(livenessImages: livenessImages,
                                                      previewImage: selfieImage)
                DispatchQueue.main.async {
                    self.processingState = .confirmation
                }
            } catch {
                DispatchQueue.main.async { [self] in
                    processingState = .error(error)
                }
            }
        }
    }

    func submit() {
        processingState = .inProgress
        var zip: Data

        do {
            let zipUrl = try LocalStorage.zipFiles(at: files)
            zip = try Data(contentsOf: zipUrl)
        } catch {
            processingState = .error(error)
            return
        }

        let jobType = isEnroll ? JobType.smartSelfieEnrollment : JobType.smartSelfieAuthentication
        let authRequest = AuthenticationRequest(jobType: jobType,
                                                enrollment: isEnroll,
                                                userId: userId,
                                                jobId: jobId)

        SmileID.api.authenticate(request: authRequest)
            .flatMap { authResponse in
                self.prepUpload(authResponse)
                    .flatMap { prepUploadResponse in
                        self.upload(prepUploadResponse, zip: zip)
                            .filter { result in
                                switch result {
                                case .response:
                                    return true
                                default:
                                    return false
                                }
                            }
                            .map { _ in authResponse }
                    }
            }
            .flatMap(pollJobStatus)
            .sink(receiveCompletion: {completion in
                switch completion {
                case .failure(let error):
                    DispatchQueue.main.async { [weak self] in
                        if let error = error as? SmileIDError {
                            switch error {
                            case .request(let urlError):
                                self?.processingState = .error(urlError)
                            case .httpError, .unknown:
                                self?.processingState = .error(error)
                            case .jobStatusTimeOut:
                                self?.processingState = .complete(nil, nil)
                            default:
                                self?.processingState = .complete(nil, error)
                            }
                        }
                    }
                default:
                    self.processingState = .complete(nil, nil)
                }
            }, receiveValue: { [weak self] response in
                DispatchQueue.main.async {
                    self?.processingState = .complete(response, nil)
                }
            }).store(in: &subscribers)
    }

    func resetCapture() {
        DispatchQueue.main.async {
            if self.processingState != nil {
                self.processingState = nil
            }
            if self.progress != 0 {
                self.progress = 0
            }
        }
        if !livenessImages.isEmpty {
            livenessImages = []
        }
        if selfieImage != nil {
            selfieImage = nil
        }
        try? LocalStorage.delete(at: files)
    }

    private func prepUpload(_ authResponse: AuthenticationResponse) -> AnyPublisher<PrepUploadResponse, Error> {
        let prepUploadRequest = PrepUploadRequest(partnerParams: authResponse.partnerParams,
                                                  timestamp: authResponse.timestamp,
                                                  signature: authResponse.signature)
        return SmileID.api.prepUpload(request: prepUploadRequest)
    }

    private func upload(_ prepUploadResponse: PrepUploadResponse, zip: Data) -> AnyPublisher<UploadResponse, Error> {
        return SmileID.api.upload(zip: zip, to: prepUploadResponse.uploadUrl)
            .eraseToAnyPublisher()
    }

    private func pollJobStatus(_ authResponse: AuthenticationResponse) -> AnyPublisher<JobStatusResponse, Error> {
        let jobStatusRequest = JobStatusRequest(userId: authResponse.partnerParams.userId,
                                                jobId: authResponse.partnerParams.jobId,
                                                includeImageLinks: false,
                                                includeHistory: false,
                                                timestamp: authResponse.timestamp,
                                                signature: authResponse.signature)

        let publisher = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .setFailureType(to: Error.self)
            .flatMap { _ in SmileID.api.getJobStatus(request: jobStatusRequest) }
            .first(where: { response in
                return response.jobComplete})
            .timeout(.seconds(10),
                     scheduler: DispatchQueue.main,
                     options: nil,
                     customError: { SmileIDError.jobStatusTimeOut })

        return publisher.eraseToAnyPublisher()
    }

    func handleClose() {
        processingState = .endFlow
    }

    func handleCompletion() {
        switch processingState {
        case .complete(let response, let error):
            pauseCameraSession()
            processingState = .endFlow
            if let error = error {
                captureResultDelegate?.didError(error: error)
                return
            }
            captureResultDelegate?.didSucceed(selfieImage: selfieImage ?? Data(),
                                              livenessImages: livenessImages,
                                              jobStatusResponse: response)
        default:
            break
        }
    }

    func handleRetry() {
        processingState = .inProgress
        submit()
    }

    func saveLivenessImage(data: Data) {
        if let photo = UIImage(data: data) {
            UIImageWriteToSavedPhotosAlbum(photo, nil, nil, nil)
        }
    }

    private func publishUnstableSceneObserved() {
        faceDetectionState = .sceneUnstable
    }

    private func publishNoFaceObserved() {
        faceDetectionState = .noFaceDetected
        faceGeometryState = .faceNotFound
        faceQualityState = .faceNotFound
        resetCapture()
    }

    private func updateProgress() {
        DispatchQueue.main.async { [self] in
            let selfieImageCount = selfieImage == nil ? 0 : 1
            progress = CGFloat(livenessImages.count+selfieImageCount)/CGFloat(numberOfLivenessImages+1)
        }
    }

    private func publishFaceObservation(_ faceDetectionState: FaceDetectionState,
                                        faceGeometryModel: FaceGeometryModel? = nil,
                                        faceQualityModel: FaceQualityModel? = nil) {
        DispatchQueue.main.async { [self] in
            self.faceDetectionState = faceDetectionState
            if let faceGeometryModel = faceGeometryModel {
                faceGeometryState = .faceFound(faceGeometryModel)
            }
            if let faceQualityModel = faceQualityModel {
                faceQualityState = .faceFound(faceQualityModel)
            }
        }
    }

    func processUpdatedFaceGeometry() {
        switch faceGeometryState {
        case .faceNotFound:
            invalidateFaceGeometryState()
        case .errored(let errorWrapper):
            print(errorWrapper.error.localizedDescription)
            invalidateFaceGeometryState()
        case .faceFound(let faceGeometryModel):
            let boundingBox = faceGeometryModel.boundingBox
            let roll = faceGeometryModel.roll.doubleValue
            let yaw = faceGeometryModel.yaw.doubleValue
            updateAcceptableBounds(using: boundingBox)
            updateAcceptableRollYaw(using: roll, yaw: yaw)
        }
    }

    func setupDirectiveSubscription() {
        throttleSubscription = subject.throttle(for: .milliseconds(300),
                                                scheduler: RunLoop.main,
                                                latest: true).sink { value in
            if value != self.directive {
                self.directive = value
            }
        }
    }
}

extension SelfieCaptureViewModel {
    func invalidateFaceGeometryState() {
        isAcceptableRoll = false
        isAcceptableYaw = false
        isAcceptableBounds = .unknown
    }

    func calculateDetectedFaceValidity() {
        hasDetectedValidFace =
        isAcceptableBounds == .detectedFaceAppropriateSizeAndPosition &&
        isAcceptableRoll &&
        isAcceptableYaw &&
        isAcceptableQuality
    }

    func updateAcceptableBounds(using boundingBox: CGRect) {
        if boundingBox.width > 0.80 * faceLayoutGuideFrame.width {
            isAcceptableBounds = .detectedFaceTooLarge
            subject.send("Instructions.FaceClose")
        } else if boundingBox.width < faceLayoutGuideFrame.width * 0.25 {
            isAcceptableBounds = .detectedFaceTooSmall
            subject.send("Instructions.FaceFar")
        } else {
            if abs(boundingBox.midX - faceLayoutGuideFrame.midX) > 100 {
                isAcceptableBounds = .detectedFaceOffCentre
                subject.send("Instructions.Start")
                resetCapture()
            } else if abs(boundingBox.midY - faceLayoutGuideFrame.midY) > 210 {
                isAcceptableBounds = .detectedFaceOffCentre
                subject.send("Instructions.Start")
                resetCapture()
            } else {
                isAcceptableBounds = .detectedFaceAppropriateSizeAndPosition
            }
        }
    }

    func updateAcceptableRollYaw(using roll: Double, yaw: Double) {
        //Roll values differ because back camera feed is in landscape
        let maxRoll = cameraManager.cameraPositon == .back ? 2.0 : 0.5
        isAcceptableRoll = abs(roll) < maxRoll
        isAcceptableYaw = abs(CGFloat(yaw)) < 0.5
    }

    func processUpdatedFaceQuality() {
        switch faceQualityState {
        case .faceNotFound:
            isAcceptableQuality = true
        case .errored(let errorWrapper):
            print(errorWrapper.error.localizedDescription)
            isAcceptableQuality = true
        case .faceFound(let faceQualityModel):
            if faceQualityModel.quality < 0.3 {
                isAcceptableQuality = true
            }
            isAcceptableQuality = true
        }
    }
}
