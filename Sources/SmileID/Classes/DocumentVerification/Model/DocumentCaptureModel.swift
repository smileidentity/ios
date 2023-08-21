import SwiftUI
import Combine
import CoreVideo
import AVFoundation

class DocumentCaptureViewModel: ObservableObject, JobSubmittable {
    enum Side {
        case front
        case back
    }
    var captureSideCopy: String {
        switch side {
        case .back:
            return "Document.Capture.Back"
        case .front:
            return "Document.Capture.Front"
        }
    }
    weak var rectangleDetectionDelegate: RectangleDetectionDelegate?
    weak var captureResultDelegate: DocumentCaptureResultDelegate?
    private var displayedRectangleResult: RectangleDetectorResult?
    private var userId: String
    private var jobId: String
    private var document: Document
    private var currentBuffer: CVPixelBuffer?
    private (set) var frontImage: UIImage?
    private (set) var backImage: UIImage?
    private var subscribers = Set<AnyCancellable>()
    private var cameraFeedSubscriber: AnyCancellable?
    private var captureSubscriber: AnyCancellable?
    private var captureBothSides: Bool
    private let rectangleFunnel = RectangleFeaturesFunnel()
    private (set) lazy var cameraManager: CameraManageable = CameraManager(orientation: .landscape)
    private (set) var side = Side.front
    private (set) var showAttribution: Bool
    @Published var processingState: ProcessingState? {
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

    init(userId: String, jobId: String, document: Document, captureBothSides: Bool, showAttribution: Bool) {
        self.userId = userId
        self.jobId = jobId
        self.document = document
        self.captureBothSides = captureBothSides
        self.showAttribution = showAttribution
        subscribeToCameraFeed()
        subscribeToImageCapture()
    }

    func subscribeToCameraFeed() {
       cameraFeedSubscriber = cameraManager.sampleBufferPublisher
            .receive(on: DispatchQueue.global())
            .compactMap({$0})
            .sink( receiveValue: { [self] buffer in
                self.currentBuffer = buffer
                let imageSize = CGSize(width: CVPixelBufferGetWidth(buffer),
                                       height: CVPixelBufferGetHeight(buffer))
                RectangleDetector.rectangle(forPixelBuffer: buffer,
                                            aspectRatio: document.aspectRatio) { rect in
                    self.processRectangle(rectangle: rect, imageSize: imageSize)
                }
            })
    }

    func subscribeToImageCapture() {
        captureSubscriber = cameraManager.capturedImagePublisher
            .receive(on: DispatchQueue.global())
            .compactMap({$0})
            .sink( receiveValue: { image in
                DispatchQueue.main.async {
                    self.processingState = .confirmation(image)
                }
            })
    }

    func captureImage() {
        cameraManager.capturePhoto()
    }

    func resetState() {

    }

    func cropImage(_ capturedImage: UIImage, quadView: QuadrilateralView) {
        guard let quad = quadView.quad, let ciImage = CIImage(image: capturedImage) else {
            return
        }
        let cgOrientation = CGImagePropertyOrientation(capturedImage.imageOrientation)
        let orientedImage = ciImage.oriented(forExifOrientation: Int32(cgOrientation.rawValue))
        let scaledQuad = quad.scale(quadView.bounds.size, capturedImage.size)

        // Cropped Image
        var cartesianScaledQuad = scaledQuad.toCartesian(withHeight: capturedImage.size.height)
        cartesianScaledQuad.reorganize()

        let filteredImage = orientedImage.applyingFilter("CIPerspectiveCorrection", parameters: [
            "inputTopLeft": CIVector(cgPoint: cartesianScaledQuad.bottomLeft),
            "inputTopRight": CIVector(cgPoint: cartesianScaledQuad.bottomRight),
            "inputBottomLeft": CIVector(cgPoint: cartesianScaledQuad.topLeft),
            "inputBottomRight": CIVector(cgPoint: cartesianScaledQuad.topRight)
        ])
        switch side {
        case .back:
            backImage = UIImage.from(ciImage: filteredImage)
        case .front:
            frontImage = UIImage.from(ciImage: filteredImage)
        }
    }

    func resumeCameraSession() {
        cameraManager.resumeSession()
    }

    func pauseCameraSession() {
        cameraManager.pauseSession()
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
            captureResultDelegate?.didSucceed(documentFrontImage: frontImage!.jpegData(compressionQuality: 1)!,
                                              documentBackImage: backImage!.jpegData(compressionQuality: 1)!,
                                              jobStatusResponse: response)
        default:
            break
        }
    }

    func submit(navigation: NavigationViewModel) {
        if captureBothSides && side == .front {
            processingState = nil
            side = .back
            navigation.navigate(destination: .documentBackCaptureInstructionScreen(documentCaptureViewModel: self,
                                                                                   delegate: captureResultDelegate),
                                style: .push)
        } else {
            processingState = .inProgress
            navigation.navigate(destination: .selfieCaptureScreen(selfieCaptureViewModel:
                                                                    SelfieCaptureViewModel(userId: userId,
                                                                                           jobId: jobId,
                                                                                           isEnroll: false),
                                                                  delegate: self),
                                style: .push)
        }
    }

    func handleDeclineButtonTap() {
        processingState = nil
    }

    func handleRetry() {
        processingState = .inProgress
        //submit()
    }

    func handleClose() {
        processingState = .endFlow
    }

    func submitJob(zip: Data) {
        let authRequest = AuthenticationRequest(jobType: .documentVerification,
                                                enrollment: false,
                                                jobId: jobId,
                                                userId: userId)

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
                            self?.handleError(error)
                        }
                    }
                default:
                    break
                }
            }, receiveValue: { [weak self] response in
                DispatchQueue.main.async {
                    self?.processingState = .complete(response, nil)
                }
            }).store(in: &subscribers)
    }

    private func handleError(_ error: SmileIDError) {
        switch error {
        case .request(let urlError):
            processingState = .error(urlError)
        case .httpError, .unknown:
            processingState = .error(error)
        case .jobStatusTimeOut:
            processingState = .complete(nil, nil)
        default:
            processingState = .complete(nil, error)
        }
    }

    private func processRectangle(rectangle: Quadrilateral?, imageSize: CGSize) {
        if let rectangle {

            self.rectangleFunnel
                .add(rectangle, currentlyDisplayedRectangle: self.displayedRectangleResult?.rectangle) { [weak self] rectangle in

                    guard let self else {
                        return
                    }

                    self.displayRectangleResult(rectangleResult: RectangleDetectorResult(rectangle: rectangle,
                                                                                         imageSize: imageSize))
                }

        } else {
            self.displayedRectangleResult = nil
            self.rectangleDetectionDelegate?.didDetectQuad(quad: nil, imageSize)
        }
    }

    @discardableResult private func displayRectangleResult(rectangleResult: RectangleDetectorResult) -> Quadrilateral {
        displayedRectangleResult = rectangleResult

        let quad = rectangleResult.rectangle.toCartesian(withHeight: rectangleResult.imageSize.height)

        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }
            self.rectangleDetectionDelegate?.didDetectQuad(quad: quad, rectangleResult.imageSize)
        }

        return quad
    }
}

extension DocumentCaptureViewModel: SmartSelfieResultDelegate {
    func didSucceed(selfieImage: Data, livenessImages: [Data], jobStatusResponse: JobStatusResponse?) {
        //Submit Job with selfie and liveness images
    }

    func didError(error: Error) {
        //Handle Error
    }
}

