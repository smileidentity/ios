import Foundation
import UIKit
import Combine

enum SelfieCaptureViewModelAction {

    // scene stabilization action
    case sceneUnstable
    // Face detection actions
    case noFaceDetected
    case smileDirective
    case multipleFacesDetected
    case faceObservationDetected(FaceGeometryModel)
    case faceQualityObservationDetected(FaceQualityModel)
}

enum ProcessingState: Equatable {
    static func == (lhs: ProcessingState, rhs: ProcessingState) -> Bool {
        switch (lhs, rhs) {
        case (let .success(response1), let .success(response2)):
            return response1.timestamp == response2.timestamp
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
    case success(JobStatusResponse)
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
    var viewDelegate: FaceDetectorDelegate? {
        didSet {
            faceDetector.viewDelegate = viewDelegate
        }
    }
    let cameraManager = CameraManager()
    let frameManager: FrameManager
    private var faceDetector = FaceDetector()
    private var subscribers = Set<AnyCancellable>()
    private var facedetectionSubscribers: AnyCancellable?
    private let numberOfLivenessImages = 7
    private let livenessImageSize = CGSize(width: 256, height: 256)
    private let selfieImageSize = CGSize(width: 320, height: 320)
    private var currentBuffer: CVPixelBuffer?
    private var files = [URL]()
    var selfieImage: Data? {
        didSet {
            updateProgress()
        }
    }
    private var livenessImages = [Data]() {
        didSet {
            updateProgress()
        }
    }
    private var lastCaptureTime: Int64 = 0
    private var interCaptureDelay = 350
    weak var captureResultDelegate: SmartSelfieResultDelegate?

    @Published private(set) var progress: CGFloat = 0
    @Published private(set) var processingState: ProcessingState? {
        didSet {
            switch processingState {
            case .none:
                setupFaceDetectionSubscriptions()
                cameraManager.resumeSession()
            case .some:
                pauseFaceDetection()
            }
        }
    }

    @Published private(set) var hasDetectedValidFace: Bool {
        didSet {
            if hasDetectedValidFace {
                captureImage()
            }
        }
    }
    @Published private(set) var isAcceptableRoll: Bool {
        didSet {
            calculateDetectedFaceValidity()
        }
    }
    @Published private(set) var isAcceptableYaw: Bool {
        didSet {
            calculateDetectedFaceValidity()
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

    @Published private(set) var faceDetectionState: FaceDetectionState
    @Published private(set) var faceGeometryState: FaceObservation<FaceGeometryModel, ErrorWrapper> {
        didSet {
            processUpdatedFaceGeometry()
        }
    }
    @Published private(set) var faceQualityState: FaceObservation<FaceQualityModel, ErrorWrapper> {
        didSet {
            processUpdatedFaceQuality()
        }
    }

    init(userId: String, jobId: String, isEnroll: Bool, showAttribution: Bool = true) {
        self.userId = userId
        self.isEnroll = isEnroll
        self.jobId = jobId
        faceDetectionState = .noFaceDetected
        isAcceptableRoll = false
        isAcceptableYaw = false
        isAcceptableBounds = .unknown
        isAcceptableQuality = false

        hasDetectedValidFace = false
        faceGeometryState = .faceNotFound
        faceQualityState = .faceNotFound
        frameManager = FrameManager(cameraManager: cameraManager)
        self.showAttribution = showAttribution
        faceDetector.model = self
        setupFaceDetectionSubscriptions()
    }

    private func setupFaceDetectionSubscriptions() {
        facedetectionSubscribers = frameManager.$sampleBuffer
            .receive(on: DispatchQueue.global())
            .compactMap { return $0 }
            .sink {
                self.faceDetector.detect(pixelBuffer: $0)
                self.currentBuffer = $0
            }
    }

    private func pauseFaceDetection() {
        facedetectionSubscribers?.cancel() // 3
        facedetectionSubscribers = nil
        cameraManager.pauseSession()
    }

    func perform(action: SelfieCaptureViewModelAction) {
        switch action {
        case .sceneUnstable:
            publishUnstableSceneObserved()
        case .noFaceDetected:
            publishNoFaceObserved()
        case .multipleFacesDetected:
            publishFaceObservation(.multipleFacesDetected)
        case .faceObservationDetected(let faceGeometry):
            publishFaceObservation(.faceDetected, faceGeometryModel: faceGeometry)
        case .faceQualityObservationDetected(let faceQualityModel):
            publishFaceObservation(.faceDetected, faceQualityModel: faceQualityModel)
        case .smileDirective:
            publishFaceObservation(.smileFrame)
        }
    }

    private func captureImage() {
        guard let currentBuffer = currentBuffer, hasDetectedValidFace == true,
              livenessImages.count < numberOfLivenessImages + 1  else {
            return
        }
        guard case let .faceFound(faceGeometry) = faceGeometryState else {
            return
        }
        while (livenessImages.count < numberOfLivenessImages) &&
                ((Date().millisecondsSince1970 - lastCaptureTime) > interCaptureDelay) {
            guard let image = ImageUtils.captureFace(from: currentBuffer,
                                                     faceGeometry: faceGeometry, padding: 95,
                                                     finalSize: livenessImageSize,
                                                     screenImageSize: viewFinderSize,
                                                     isGreyScale: true) else { return }
            livenessImages.append(image)
            lastCaptureTime = Date().millisecondsSince1970
        }

        if livenessImages.count >= 3 {
            perform(action: .smileDirective)
        }

        if (livenessImages.count == numberOfLivenessImages) &&
            ((Date().millisecondsSince1970 - lastCaptureTime) > interCaptureDelay) &&
            selfieImage == nil {
            publishFaceObservation(.finalFrame)
            guard let selfieImage = ImageUtils.captureFace(from: currentBuffer,
                                                           faceGeometry: faceGeometry, padding: 200,
                                                           finalSize: selfieImageSize,
                                                           screenImageSize: viewFinderSize,
                                                           isGreyScale: false) else { return }
            lastCaptureTime = Date().millisecondsSince1970
            self.selfieImage = selfieImage
            do {
                files = try LocalStorage.saveImageJpg(livenessImages: livenessImages,
                                                                      previewImage: selfieImage)
                processingState = .confirmation
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
                        print("error is \(error.localizedDescription)")
                        self?.processingState = .error(error)
                    }
                default:
                    break
                }
            }, receiveValue: { [weak self] response in
                DispatchQueue.main.async {
                    self?.processingState = .success(response)
                }
            }).store(in: &subscribers)
    }

    func resetCapture() {
        livenessImages = []
        selfieImage = nil
        try? LocalStorage.delete(at: files)
        processingState = nil
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

    func handleSuccess() {
        switch processingState {
        case .success(let response):
            processingState = .endFlow
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

    private func handleUploadResponse(_ response: JobStatusResponse) {
        processingState = .success(response)
    }

    func saveLivenessImage(data: Data) {
        if let photo = UIImage(data: data) {
            UIImageWriteToSavedPhotosAlbum(photo, nil, nil, nil)
        }
    }

    private func publishUnstableSceneObserved() {
        DispatchQueue.main.async { [self] in
            faceDetectionState = .sceneUnstable
        }
    }

    private func publishNoFaceObserved() {
        DispatchQueue.main.async { [self] in
            faceDetectionState = .noFaceDetected
            faceGeometryState = .faceNotFound
            faceQualityState = .faceNotFound
        }
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
        if boundingBox.width > 0.9 * faceLayoutGuideFrame.width {
            isAcceptableBounds = .detectedFaceTooLarge
        } else if boundingBox.width < faceLayoutGuideFrame.width * 0.25 {
            isAcceptableBounds = .detectedFaceTooSmall
        } else {
            if abs(boundingBox.midX - faceLayoutGuideFrame.midX) > 100 {
                isAcceptableBounds = .detectedFaceOffCentre
                resetCapture()
            } else if abs(boundingBox.midY - faceLayoutGuideFrame.midY) > 210 {
                isAcceptableBounds = .detectedFaceOffCentre
                resetCapture()
            } else {
                isAcceptableBounds = .detectedFaceAppropriateSizeAndPosition
            }
        }
    }

    func updateAcceptableRollYaw(using roll: Double, yaw: Double) {
        isAcceptableRoll = abs(roll) < 0.5
        isAcceptableYaw = abs(CGFloat(yaw)) < 0.15
    }

    func processUpdatedFaceQuality() {
        switch faceQualityState {
        case .faceNotFound:
            isAcceptableQuality = false
        case .errored(let errorWrapper):
            print(errorWrapper.error.localizedDescription)
            isAcceptableQuality = false
        case .faceFound(let faceQualityModel):
            if faceQualityModel.quality < 0.3 {
                isAcceptableQuality = false
            }
            isAcceptableQuality = true
        }
    }
}
