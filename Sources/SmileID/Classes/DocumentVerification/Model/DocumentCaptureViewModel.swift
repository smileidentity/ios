import Combine
import SwiftUI

enum DocumentDirective: String {
    case defaultInstructions = "Document.Directive.Default"
    case capturing = "Document.Directive.Capturing"
}

private let correctAspectRatioTolerance = 0.1
private let centeredTolerance = 30.0
private let documentAutoCaptureWaitTimeSecs = 1.0

class DocumentCaptureViewModel: ObservableObject {
    // Initializer properties
    private let knownAspectRatio: Double?

    // Other properties
    private let defaultAspectRatio: Double
    private let textDetector = TextDetector()
    private var imageCaptureSubscriber: AnyCancellable?
    private var cameraBufferSubscriber: AnyCancellable?
    private var processingImage = false
    private var documentFirstDetectedAtTime: TimeInterval?
    private var areEdgesDetectedSubscriber: AnyCancellable?

    // UI properties
    // TODO: Mark these as @MainActor?
    @Published var acknowledgedInstructions = false
    @Published var showPhotoPicker = false
    @Published var directive: DocumentDirective = .defaultInstructions
    @Published var areEdgesDetected = false
    @Published var idAspectRatio = 1.0
    @Published var showManualCaptureButton = false
    @Published var documentImageToConfirm: Data?
    @Published var captureError: Error?
    @Published var isCapturing = false
    @Published var cameraManager = CameraManager(orientation: .portrait)

    init(knownAspectRatio: Double? = nil) {
        self.knownAspectRatio = knownAspectRatio
        defaultAspectRatio = knownAspectRatio ?? 1.0
        DispatchQueue.main.async { [self] in
            idAspectRatio = defaultAspectRatio
        }

        imageCaptureSubscriber = cameraManager.capturedImagePublisher
            .receive(on: DispatchQueue.global())
            .compactMap { $0 }
            .sink(receiveValue: onCaptureComplete)

        cameraBufferSubscriber = cameraManager.sampleBufferPublisher
            .receive(on: DispatchQueue(label: "com.smileidentity.receivebuffer"))
            .compactMap { $0 }
            .sink(receiveValue: analyzeImage)

        // Show Manual Capture button after 10 seconds
        Timer.scheduledTimer(
            timeInterval: 10,
            target: self,
            selector: #selector(showManualCapture),
            userInfo: nil,
            repeats: false
        )

        // Auto capture after 1 second of edges detected
        areEdgesDetectedSubscriber = $areEdgesDetected.sink(receiveValue: { areEdgesDetected in
            if areEdgesDetected {
                if let documentFirstDetectedAtTime = self.documentFirstDetectedAtTime {
                    let now = Date().timeIntervalSince1970
                    let elapsedTime = now - documentFirstDetectedAtTime
                    if elapsedTime > documentAutoCaptureWaitTimeSecs && !self.isCapturing {
                        self.captureDocument()
                    }
                } else {
                    self.documentFirstDetectedAtTime = Date().timeIntervalSince1970
                }
            } else {
                self.documentFirstDetectedAtTime = nil
            }
        })
    }

    @objc func showManualCapture() {
        DispatchQueue.main.async {
            self.showManualCaptureButton = true
        }
    }

    /// Called when the user taps the "Take Photo" button on the instructions screen. This is NOT
    /// the same as the manual capture button.
    func onTakePhotoClick() {
        DispatchQueue.main.async {
            self.isCapturing = false
            self.acknowledgedInstructions = true
        }
    }

    /// Called when the user taps the "Select from Gallery" button on the instructions screen
    func onGalleryClick() {
        showPhotoPicker = true
    }

    func onPhotoSelectedFromGallery(_ image: UIImage) {
        guard let image = image.jpegData(compressionQuality: 1.0) else {
            DispatchQueue.main.async {
                self.captureError = SmileIDError.unknown("Error saving image")
            }
            return
        }
        DispatchQueue.main.async {
            self.acknowledgedInstructions = true
            self.documentImageToConfirm = image
            self.showPhotoPicker = false
        }
    }

    /// Called when auto capture determines the image quality is sufficient OR when the user taps
    /// the manual capture button.
    func captureDocument() {
        if (isCapturing) {
            print("Already capturing. Skipping duplicate capture request")
            return
        }
        DispatchQueue.main.async {
            self.isCapturing = true
            self.directive = .capturing
        }
        cameraManager.capturePhoto()
    }

    /// Called if the user declines the image in the capture confirmation dialog.
    func onRetry() {
        DispatchQueue.main.async {
            self.isCapturing = false
            self.acknowledgedInstructions = false
            self.documentImageToConfirm = nil
            self.captureError = nil
            self.directive = .defaultInstructions
            self.areEdgesDetected = false
        }
    }

    private func onCaptureComplete(image: Data) {
        DispatchQueue.main.async { [self] in
            documentImageToConfirm = image
            isCapturing = false
        }
    }

    /// Analyzes a single frame from the camera. No other frame will be processed until this one
    /// completes. This is to prevent the UI from flickering between different states.
    ///
    /// Unlike Android, we don't perform focus and luminance detection, as text detection serves as
    /// a better proxy for image quality.
    ///
    /// - Parameter buffer: The pixel buffer to analyze
    private func analyzeImage(buffer: CVPixelBuffer) {
        if (processingImage) {
            return
        }
        processingImage = true
        let imageSize = CGSize(
            width: CVPixelBufferGetWidth(buffer),
            height: CVPixelBufferGetHeight(buffer)
        )
        RectangleDetector.rectangle(
            forPixelBuffer: buffer,
            aspectRatio: knownAspectRatio
        ) { [self] rect in
            if rect == nil {
                resetBoundingBox()
                processingImage = false
                return
            }
            let detectedAspectRatio = 1 / (rect?.aspectRatio ?? defaultAspectRatio)
            let isCorrectAspectRatio = isCorrectAspectRatio(
                detectedAspectRatio: detectedAspectRatio
            )
            let idAspectRatio = knownAspectRatio ?? detectedAspectRatio
            let isCentered = isRectCentered(
                detectedRect: rect,
                imageWidth: Double(imageSize.width),
                imageHeight: Double(imageSize.height)
            )
            DispatchQueue.main.async { [self] in
                self.idAspectRatio = idAspectRatio
            }
            textDetector.detectText(buffer: buffer) { [self] hasText in
                processingImage = false
                let areEdgesDetected = isCentered && isCorrectAspectRatio && hasText
                DispatchQueue.main.async { [self] in
                    self.areEdgesDetected = areEdgesDetected
                }
            }
        }
    }

    private func resetBoundingBox() {
        DispatchQueue.main.async {
            self.areEdgesDetected = false
            self.idAspectRatio = self.defaultAspectRatio
        }
    }

    private func isCorrectAspectRatio(
        detectedAspectRatio: Double,
        tolerance: Double = correctAspectRatioTolerance
    ) -> Bool {
        let expectedAspectRatio = knownAspectRatio ?? detectedAspectRatio
        return abs(detectedAspectRatio - expectedAspectRatio) < tolerance
    }

    private func isRectCentered(
        detectedRect: Quadrilateral?,
        imageWidth: Double,
        imageHeight: Double,
        tolerance: Double = centeredTolerance
    ) -> Bool {
        guard let detectedRect = detectedRect else { return false }

        // Sometimes, the bounding box is out of frame. This cannot be considered centered
        // We check only left and right because the document should always fill the width but may
        // not fill the height
        if detectedRect.topLeft.x < tolerance || detectedRect.topRight.x > imageWidth - tolerance {
            return false
        }

        let imageCenterX = imageWidth / 2
        let imageCenterY = imageHeight / 2

        let rectCenterX = (detectedRect.topLeft.x + detectedRect.topRight.x) / 2
        let rectCenterY = (detectedRect.topLeft.y + detectedRect.bottomLeft.y) / 2

        let deltaX = abs(imageCenterX - rectCenterX)
        let deltaY = abs(imageCenterY - rectCenterY)

        let isCenteredHorizontally = deltaX < tolerance
        let isCenteredVertically = deltaY < tolerance

        return isCenteredHorizontally && isCenteredVertically
    }
}

struct DocumentCaptureScreen: View {
    let showInstructions: Bool
    let showAttribution: Bool
    let allowGallerySelection: Bool
    let showSkipButton: Bool
    let instructionsTitleText: String
    let instructionsSubtitleText: String
    let captureTitleText: String
    let knownIdAspectRatio: Double?
    let onConfirm: (Data) -> Void
    let onError: (Error) -> Void
    let onSkip: () -> Void
    @ObservedObject private var viewModel: DocumentCaptureViewModel

    init(
        showInstructions: Bool,
        showAttribution: Bool,
        allowGallerySelection: Bool,
        showSkipButton: Bool,
        instructionsTitleText: String,
        instructionsSubtitleText: String,
        captureTitleText: String,
        knownIdAspectRatio: Double?,
        onConfirm: @escaping (Data) -> Void,
        onError: @escaping (Error) -> Void,
        onSkip: @escaping () -> Void = {}
    ) {
        self.showInstructions = showInstructions
        self.showAttribution = showAttribution
        self.allowGallerySelection = allowGallerySelection
        self.showSkipButton = showSkipButton
        self.instructionsTitleText = instructionsTitleText
        self.instructionsSubtitleText = instructionsSubtitleText
        self.captureTitleText = captureTitleText
        self.knownIdAspectRatio = knownIdAspectRatio
        self.onConfirm = onConfirm
        self.onError = onError
        self.onSkip = onSkip
        viewModel = DocumentCaptureViewModel(knownAspectRatio: knownIdAspectRatio)
    }

    var body: some View {
        if let captureError = viewModel.captureError {
            let _ = onError(captureError)
        } else if showInstructions && !viewModel.acknowledgedInstructions {
            DocumentCaptureInstructionsScreen(
                title: instructionsTitleText,
                subtitle: instructionsSubtitleText,
                showAttribution: showAttribution,
                allowPhotoFromGallery: allowGallerySelection,
                showSkipButton: showSkipButton,
                onSkip: onSkip,
                onInstructionsAcknowledgedSelectFromGallery: viewModel.onGalleryClick,
                onInstructionsAcknowledgedTakePhoto: viewModel.onTakePhotoClick
            )
                .sheet(isPresented: $viewModel.showPhotoPicker) {
                    ImagePicker(onImageSelected: viewModel.onPhotoSelectedFromGallery)
                }
        } else if let imageToConfirm = viewModel.documentImageToConfirm {
            ImageCaptureConfirmationDialog(
                title: SmileIDResourcesHelper.localizedString(for: "Document.Confirmation.Header"),
                subtitle: SmileIDResourcesHelper.localizedString(
                    for: "Document.Confirmation.Callout"
                ),
                image: UIImage(data: imageToConfirm) ?? UIImage(),
                confirmationButtonText: SmileIDResourcesHelper.localizedString(
                    for: "Document.Confirmation.Accept"
                ),
                onConfirm: { onConfirm(imageToConfirm) },
                retakeButtonText: SmileIDResourcesHelper.localizedString(
                    for: "Document.Confirmation.Decline"
                ),
                onRetake: viewModel.onRetry
            )
        } else {
            CaptureScreenContent(
                title: captureTitleText,
                subtitle: SmileIDResourcesHelper.localizedString(for: viewModel.directive.rawValue),
                idAspectRatio: viewModel.idAspectRatio,
                areEdgesDetected: viewModel.areEdgesDetected,
                showCaptureInProgress: viewModel.isCapturing,
                showManualCaptureButton: viewModel.showManualCaptureButton,
                cameraManager: viewModel.cameraManager,
                onCaptureClick: viewModel.captureDocument
            )
        }
    }
}

struct CaptureScreenContent: View {
    let title: String
    let subtitle: String
    let idAspectRatio: Double
    let areEdgesDetected: Bool
    let showCaptureInProgress: Bool
    let showManualCaptureButton: Bool
    let cameraManager: CameraManager
    let onCaptureClick: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            ZStack {
                CameraView(cameraManager: cameraManager)
                    .onAppear { cameraManager.switchCamera(to: .back) }
                    .onDisappear(perform: cameraManager.pauseSession)
                DocumentShapedBoundingBox(
                    aspectRatio: idAspectRatio,
                    borderColor: areEdgesDetected ? SmileID.theme.success : .gray
                )
            }
            Text(title)
                .multilineTextAlignment(.center)
                .font(SmileID.theme.header4)
                .foregroundColor(SmileID.theme.accent)
                .frame(alignment: .center)
                .padding()
            Text(subtitle)
                .multilineTextAlignment(.center)
                .font(SmileID.theme.body)
                .foregroundColor(SmileID.theme.accent)
                .frame(alignment: .center)
                .padding()
            Spacer()
            VStack(alignment: .center, spacing: 16) {
                if showCaptureInProgress {
                    ActivityIndicator(isAnimating: true).padding()
                } else if showManualCaptureButton {
                    CaptureButton(action: onCaptureClick).padding()
                } else {
                    Spacer()
                }
                // By using a fixed size here, we ensure the UI doesn't move around when the
                // manual capture button becomes visible
            }
                .frame(height: 64)
            Spacer()
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
