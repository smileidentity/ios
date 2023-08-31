import SwiftUI
import Combine
import CoreVideo
import AVFoundation

class DocumentCaptureViewModel: ObservableObject, JobSubmittable, ConfirmationDialogContract {
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
    var confirmationImage: UIImage {
        switch side {
        case .back:
            return backImage ?? UIImage()
        case .front:
            return frontImage ?? UIImage()
        }
    }
    weak var rectangleDetectionDelegate: RectangleDetectionDelegate?
    weak var captureResultDelegate: DocumentCaptureResultDelegate?
    var router: Router<NavigationDestination>?
    private var cameraCapture: Bool = false
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
    private (set) var allowGalleryUpload: Bool
    private var selfie: Data?
    private var livenessImages: [Data]?
    private var files = [URL]()
    private var recieveBufferQueue = DispatchQueue(label: "com.smileid.receivebuffer")
    @State var galleryImageFront = UIImage() {
        didSet {
            frontImage = galleryImageFront
        }
    }
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

    @Published var borderColor: UIColor = .gray
    @Published var guideSize: CGSize = .zero
    var width: CGFloat = .zero

    var rectangleAspectRatio: Double = 1.66 {
        didSet {
            let rectWidth = 0.9 * width
            let rectHeight = rectWidth/rectangleAspectRatio
            DispatchQueue.main.async {
                self.guideSize = CGSize(width: rectWidth, height: rectHeight)
            }
        }
    }

    init(userId: String,
         jobId: String,
         document: Document,
         selfie: Data? = nil,
         captureBothSides: Bool,
         showAttribution: Bool,
         allowGalleryUpload: Bool) {
        self.userId = userId
        self.jobId = jobId
        self.document = document
        self.selfie = selfie
        self.captureBothSides = captureBothSides
        self.showAttribution = showAttribution
        self.allowGalleryUpload = allowGalleryUpload
        subscribeToCameraFeed()
        subscribeToImageCapture()
    }

    func subscribeToCameraFeed() {
       cameraFeedSubscriber = cameraManager.sampleBufferPublisher
            .receive(on: recieveBufferQueue)
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
                    self.cameraCapture = true
                    self.processingState = .confirmation(image)
                    self.router?.push(.documentConfirmation(viewModel: self, image: image))
                }
            })
    }

    func captureImage() {
        cameraManager.capturePhoto()
    }

    func resetState() {
        DispatchQueue.main.async {
            self.processingState = nil
        }
        frontImage = nil
        backImage = nil
        displayedRectangleResult = nil
        currentBuffer = nil
        files = []
        // TO-DO: Add check flag to know if partner supplied the selfie
        selfie = nil
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

    func acceptImage() {
        submit()
    }

    func declineImage() {
        if cameraCapture {
            processingState = nil
        } else {
            resetState()
        }
        router?.pop()
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
            if let selfie = selfie {
                captureResultDelegate?.didSucceed(selfie: selfie,
                                                  documentFrontImage: frontImage!.jpegData(compressionQuality: 1)!,
                                                  documentBackImage: backImage!.jpegData(compressionQuality: 1)!,
                                                  jobStatusResponse: response)
            }
        default:
            break
        }
    }

    func submit() {
        if captureBothSides && side == .front {
            processingState = nil
            side = .back
            router?.push(.documentBackCaptureInstructionScreen(documentCaptureViewModel: self,
                                                              delegate: captureResultDelegate))
        } else {
            processingState = .inProgress
            router?.push(.selfieCaptureScreen(selfieCaptureViewModel:
                                                SelfieCaptureViewModel(userId: userId,
                                                                       jobId: jobId,
                                                                       isEnroll: false,
                                                                       shoudSubmitJob: false),
                                              delegate: self))
        }
    }

    func handleRetry() {
        processingState = .inProgress
                router?.push(.doucmentCaptureProcessing)
        submitJob()
    }

    func handleClose() {
        processingState = .endFlow
    }

    func submitJob() {
        var zip: Data
        do {
            let zipUrl = try LocalStorage.zipFiles(at: files)
            zip = try Data(contentsOf: zipUrl)
        } catch {
            captureResultDelegate?.didError(error: error)
            return
        }
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
                    self?.router?.push(.documentCaptureComplete(viewModel: self!))
                }
            }).store(in: &subscribers)
    }

    private func handleError(_ error: SmileIDError) {
        switch error {
        case .request, .httpError:
            router?.push(.documentCaptureError(viewModel: self))
        case .unknown:
            router?.push(.documentCaptureError(viewModel: self))
        case .jobStatusTimeOut:
            processingState = .complete(nil, nil)
            router?.push(.documentCaptureComplete(viewModel: self))
        default:
            processingState = .complete(nil, error)
            router?.push(.documentCaptureComplete(viewModel: self))
        }
    }

    private func processRectangle(rectangle: Quadrilateral?, imageSize: CGSize) {
        if let rectangle {
            self.rectangleFunnel
                .add(rectangle, currentlyDisplayedRectangle: self.displayedRectangleResult?.rectangle) { [weak self] rectangle in

                    guard let self else {
                        return
                    }
                    self.rectangleAspectRatio = rectangle.aspectRatio
                    self.displayRectangleResult(rectangleResult: RectangleDetectorResult(rectangle: rectangle,
                                                                                         imageSize: imageSize))
                }
        } else {
            self.displayedRectangleResult = nil
            self.rectangleDetectionDelegate?.didDetectQuad(quad: nil, imageSize)
        }
    }

    func isRectangleValid() {
        borderColor = .green
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

    func saveFilesToDisk() {
        if !files.isEmpty {
            try? LocalStorage.delete(at: files)
        }
        do {
            files = try LocalStorage.saveDocumentImages(front: frontImage!.jpegData(compressionQuality: 1)!,
                                                        back: backImage?.jpegData(compressionQuality: 1),
                                                        livenessImages: livenessImages,
                                                        selfie: selfie!,
                                                        document: document)
        }
        catch {
            captureResultDelegate?.didError(error: error)
        }
    }
}

extension DocumentCaptureViewModel: SmartSelfieResultDelegate {
    func didSucceed(selfieImage: Data, livenessImages: [Data], jobStatusResponse: JobStatusResponse?) {
        router?.push( .doucmentCaptureProcessing)
        selfie = selfieImage
        self.livenessImages = livenessImages
        saveFilesToDisk()
        submitJob()
    }

    func didError(error: Error) {
        captureResultDelegate?.didError(error: error)
    }
}

extension DocumentCaptureViewModel: ImagePickerDelegate {
    func didSelect(image: UIImage) {
        switch side {
        case .back:
            backImage = image
        case .front:
            frontImage = image
        }
        cameraCapture = false
        router?.push(.documentConfirmation(viewModel: self, image: image))
    }
}

