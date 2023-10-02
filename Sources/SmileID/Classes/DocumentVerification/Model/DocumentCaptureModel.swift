import SwiftUI
import Combine
import CoreVideo
import AVFoundation

class DocumentCaptureViewModel: ObservableObject,
    JobSubmittable,
    ConfirmationDialogContract,
    TextDetectionDelegate {

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
    private let textDetector = TextDetector()
    private var displayedRectangleResult: RectangleDetectorResult?
    private var userId: String
    private var jobId: String
    private var countryCode: String
    private var documentType: String?
    private var idAspectRatio: Double?
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
    private var savedFiles: DocumentCaptureResultStore?
    private var textDetected = false
    private var receiveBufferQueue = DispatchQueue(label: "com.smileidentity.receivebuffer")
    private let autoCaptureDelayInSecs: TimeInterval = 2
    private let manualCaptureDelayInSecs: TimeInterval = 10
    private var autoCaptureTimer: RestartableTimer?
    private var manualCaptureTimer: Timer?

    @State var galleryImageFront = UIImage() {
        didSet { frontImage = galleryImageFront }
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

    @Published var showCaptureButton = false
    @Published var isCapturing = false
    @Published var borderColor: UIColor = .gray
    @Published var guideSize: CGSize = CGSize(
        width: UIScreen.main.bounds.width * 0.9,
        height: UIScreen.main.bounds.width / 1.66
    )
    var width: CGFloat = .zero
    var height: CGFloat = .zero

    var rectangleAspectRatio: Double = 1.66 {
        didSet {
            let rectWidth = 0.9 * width
            let rectHeight = min(rectWidth / rectangleAspectRatio, 0.9 * height)

            DispatchQueue.main.async {
                self.guideSize = CGSize(width: rectWidth, height: rectHeight)
            }
        }
    }

    init(
        userId: String,
        jobId: String,
        countryCode: String,
        documentType: String?,
        idAspectRatio: Double? = nil,
        selfie: Data? = nil,
        captureBothSides: Bool,
        showAttribution: Bool,
        allowGalleryUpload: Bool
    ) {
        self.userId = userId
        self.jobId = jobId
        self.documentType = documentType
        self.countryCode = countryCode
        self.idAspectRatio = idAspectRatio
        self.selfie = selfie
        self.captureBothSides = captureBothSides
        self.showAttribution = showAttribution
        self.allowGalleryUpload = allowGalleryUpload

        autoCaptureTimer = RestartableTimer(
            timeInterval: autoCaptureDelayInSecs,
            target: self,
            selector: #selector(captureImage)
        )
        manualCaptureTimer = Timer.scheduledTimer(
            timeInterval: manualCaptureDelayInSecs,
            target: self,
            selector: #selector(showManualCapture),
            userInfo: nil,
            repeats: false
        )

        textDetector.delegate = self
        subscribeToCameraFeed()
        subscribeToImageCapture()
    }

    func subscribeToCameraFeed() {
        cameraFeedSubscriber = cameraManager.sampleBufferPublisher
            .receive(on: receiveBufferQueue)
            .compactMap { $0 }
            .sink(receiveValue: { [self] buffer in
                currentBuffer = buffer
                let imageSize = CGSize(
                    width: CVPixelBufferGetWidth(buffer),
                    height: CVPixelBufferGetHeight(buffer)
                )
                textDetector.detectText(buffer: buffer)
                RectangleDetector.rectangle(
                    forPixelBuffer: buffer,
                    aspectRatio: idAspectRatio
                ) { [self] rect in
                    processRectangle(rectangle: rect, imageSize: imageSize)
                }
            })
    }

    func subscribeToImageCapture() {
        captureSubscriber = cameraManager.capturedImagePublisher
            .receive(on: DispatchQueue.global())
            .compactMap { $0 }
            .sink(receiveValue: { image in
                DispatchQueue.main.async {
                    self.cameraCapture = true
                    self.processingState = .confirmation(image)
                    self.cropImage(image)
                }
            })
    }

    @objc func captureImage() {
        cameraManager.capturePhoto()
        DispatchQueue.main.async {
            self.isCapturing = true
        }
    }

    func resetState() {
        DispatchQueue.main.async {
            self.processingState = nil
        }
        frontImage = nil
        backImage = nil
        displayedRectangleResult = nil
        currentBuffer = nil
        savedFiles = nil
        // TO-DO: Add check flag to know if partner supplied the selfie
        selfie = nil
    }

    func cropImage(_ capturedImage: UIImage) {
        guard let ciImage = CIImage(image: capturedImage) else { return }
        let transparentRectOrigin = CGPoint(
            x: (width - guideSize.width) / 2,
            y: (height - guideSize.height) / 2
        )

        let rect = CGRect(origin: transparentRectOrigin, size: self.guideSize)

        let cropQuad = Quadrilateral(cgRect: rect)
        let cgOrientation = CGImagePropertyOrientation(capturedImage.imageOrientation)
        let orientedImage = ciImage.oriented(forExifOrientation: Int32(cgOrientation.rawValue))
        let scaledQuad = cropQuad.scale(CGSize(width: width, height: height), capturedImage.size)
        var cartesianScaledQuad = scaledQuad.toCartesian(withHeight: capturedImage.size.height)
        cartesianScaledQuad.reorganize()
        let filteredImage = orientedImage.applyingFilter(
            "CIPerspectiveCorrection",
            parameters: [
                "inputTopLeft": CIVector(cgPoint: cartesianScaledQuad.bottomLeft),
                "inputTopRight": CIVector(cgPoint: cartesianScaledQuad.bottomRight),
                "inputBottomLeft": CIVector(cgPoint: cartesianScaledQuad.topLeft),
                "inputBottomRight": CIVector(cgPoint: cartesianScaledQuad.topRight)
            ]
        )
        let croppedImage = UIImage.from(ciImage: filteredImage)
        switch side {
        case .back:
            backImage = croppedImage
        case .front:
            frontImage = croppedImage
        }
        router?.push(.documentConfirmation(viewModel: self, image: croppedImage))
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

    func handleInstructionsBackButtonTap(side: DocumentCaptureInstructionsView.Side) {
        switch side {
        case .front:
            router?.dismiss()
        case .back:
            router?.pop()
        }
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
            if let savedFiles = savedFiles, let response = response {
                captureResultDelegate?.didSucceed(
                    selfie: savedFiles.selfie,
                    documentFrontImage: savedFiles.documentFront,
                    documentBackImage: savedFiles.documentBack,
                    jobStatusResponse: response
                )
            }
        default:
            break
        }
    }

    func submit() {
        let selfieCaptureScreen = NavigationDestination.selfieCaptureScreen(
            selfieCaptureViewModel: SelfieCaptureViewModel(
                userId: userId,
                jobId: jobId,
                isEnroll: false,
                shouldSubmitJob: false,
                imageCaptureDelegate: self
            ),
            delegate: self
        )
        if captureBothSides && side == .front {
            side = .back
            pauseCameraSession()
            router?.push(
                .documentBackCaptureInstructionScreen(
                    documentCaptureViewModel: self,
                    skipDestination: selfieCaptureScreen,
                    delegate: captureResultDelegate
                )
            )
        } else {
            processingState = .inProgress
            router?.push(selfieCaptureScreen)
        }
    }

    func handleRetry() {
        processingState = .inProgress
        router?.push(.documentCaptureProcessing)
        submitJob()
    }

    func handleClose() {
        processingState = .endFlow
    }

    func submitJob() {
        guard let savedFiles = savedFiles else { return }
        var zip: Data
        do {
            let zipUrl = try LocalStorage.zipFiles(at: savedFiles.allFiles)
            zip = try Data(contentsOf: zipUrl)
        } catch {
            captureResultDelegate?.didError(error: error)
            return
        }
        let authRequest = AuthenticationRequest(
            jobType: .documentVerification,
            enrollment: false,
            jobId: jobId,
            userId: userId
        )

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
            .flatMap(getJobStatus)
            .sink(receiveCompletion: { completion in
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
            })
            .store(in: &subscribers)
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

    @objc func showManualCapture() {
        DispatchQueue.main.async {
            self.showCaptureButton = true
        }
    }

    private func processRectangle(rectangle: Quadrilateral?, imageSize: CGSize) {
        if let rectangle {
            rectangleFunnel.add(
                rectangle,
                currentlyDisplayedRectangle: displayedRectangleResult?.rectangle
            ) { [weak self] rectangle in
                guard let self else { return }
                rectangleAspectRatio = rectangle.aspectRatio
                displayRectangleResult(
                    rectangleResult: RectangleDetectorResult(
                        rectangle: rectangle,
                        imageSize: imageSize
                    )
                )
            }
        } else {
            displayedRectangleResult = nil
            rectangleDetectionDelegate?.didDetectQuad(quad: nil, imageSize, completion: nil)
        }
    }

    @discardableResult private func displayRectangleResult(
        rectangleResult: RectangleDetectorResult
    ) -> Quadrilateral {
        displayedRectangleResult = rectangleResult
        let quad = rectangleResult.rectangle.toCartesian(
            withHeight: rectangleResult.imageSize.height
        )

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.rectangleDetectionDelegate?.didDetectQuad(
                quad: quad,
                rectangleResult.imageSize
            ) { [self] transformedQuad in
                let transparentRectOrigin = CGPoint(
                    x: (self.width - self.guideSize.width) / 2,
                    y: (self.height - self.guideSize.height) / 2
                )
                let rect = CGRect(origin: transparentRectOrigin, size: self.guideSize)

                if self.textDetected && self.isWithinBoundsAndSize(
                    cgrect1: rect,
                    cgrect2: transformedQuad.cgRect
                ) {
                    self.borderColor = SmileID.theme.success.uiColor()
                    if !(self.autoCaptureTimer?.isValid ?? false) {
                        self.autoCaptureTimer?.restart()
                    }
                } else {
                    self.autoCaptureTimer?.stop()
                    self.isCapturing = false
                    self.borderColor = .gray
                }
            }
        }

        return quad
    }

    func noTextDetected() {
        DispatchQueue.main.async { [weak self] in
            self?.borderColor = .gray
        }
        autoCaptureTimer?.stop()
        isCapturing = false
        textDetected = false
    }

    func onTextDetected() {
        textDetected = true
    }

    func isWithinBoundsAndSize(cgrect1: CGRect, cgrect2: CGRect) -> Bool {
        // Check if cgrect2 is fully contained within cgrect1
        if !cgrect1.contains(cgrect2) {
            return false
        }

        // Calculate the areas of cgrect1 and cgrect2
        let area1 = cgrect1.width * cgrect1.height
        let area2 = cgrect2.width * cgrect2.height

        // Check if cgrect2's area is at least 30% but not more than 100% of cgrect1's area
        return area2 >= 0.3 * area1 && area2 <= area1
    }

    func saveFilesToDisk() {
        if let savedFiles = savedFiles, !savedFiles.allFiles.isEmpty {
            try? LocalStorage.delete(at: savedFiles.allFiles)
        }
        do {
            savedFiles = try LocalStorage.saveDocumentImages(
                front: frontImage!.jpegData(compressionQuality: 1)!,
                back: backImage?.jpegData(compressionQuality: 1),
                selfie: selfie!,
                livenessImages: livenessImages,
                countryCode: countryCode,
                documentType: documentType
            )
        } catch {
            captureResultDelegate?.didError(error: error)
        }
    }
}

extension DocumentCaptureViewModel: SmartSelfieResultDelegate, SelfieImageCaptureDelegate {
    func didCapture(selfie: Data, livenessImages: [Data]) {
        router?.push(.documentCaptureProcessing)
        self.selfie = selfie
        self.livenessImages = livenessImages
        saveFilesToDisk()
        submitJob()
    }

    func didSucceed(
        selfieImage: URL,
        livenessImages: [URL],
        jobStatusResponse: JobStatusResponse
    ) {}

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
