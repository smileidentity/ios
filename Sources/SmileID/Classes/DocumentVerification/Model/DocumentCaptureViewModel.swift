import Combine
import CoreMotion
import Foundation
import SwiftUI
import MLKitObjectDetection
import MLKitVision

enum DocumentDirective: String {
    case defaultInstructions = "Document.Directive.Default"
    case capturing = "Document.Directive.Capturing"
}

private let correctAspectRatioTolerance = 0.1
private let centeredTolerance = 30.0
private let documentAutoCaptureWaitTime: TimeInterval = 1.0
private let analysisSampleInterval: TimeInterval = 0.350

class DocumentCaptureViewModel: ObservableObject {

    // ML Kit Object Detection
    private let objectDetector: ObjectDetector
    
    deinit {
        subscribers.removeAll()
    }
    
    // Initializer properties
    private let knownAspectRatio: Double?
    private let metadata: Metadata = .shared
    private var captureDuration = MonotonicTime()

    // Other properties
    private let defaultAspectRatio: Double
    private let textDetector = TextDetector()
    private var subscribers = Set<AnyCancellable>()
    private var processingImage = false
    private var documentFirstDetectedAtTime: TimeInterval?
    private var lastAnalysisTime: TimeInterval = 0
    private var areEdgesDetectedSubscriber: AnyCancellable?
    private let side: DocumentCaptureSide
    private var retryCount: Int = 0
    private(set) var documentImageOrigin: DocumentImageOriginValue?
    private var hasRecordedOrientationAtCaptureStart = false

    // UI properties
    @Published var unauthorizedAlert: AlertState?
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

    init(
        knownAspectRatio: Double? = nil,
        side: DocumentCaptureSide
    ) {
        let options = ObjectDetectorOptions()
        options.shouldEnableClassification = true
        options.detectorMode = .singleImage
        self.objectDetector = ObjectDetector.objectDetector(options: options)
        
        self.knownAspectRatio = knownAspectRatio
        self.side = side
        defaultAspectRatio = knownAspectRatio ?? 1.0
        DispatchQueue.main.async { [self] in
            idAspectRatio = defaultAspectRatio
        }

        cameraManager.$status
            .receive(on: DispatchQueue.main)
            .filter { $0 == .unauthorized }
            .map { _ in AlertState.cameraUnauthorized }
            .sink { alert in self.unauthorizedAlert = alert }
            .store(in: &subscribers)

        cameraManager.capturedImagePublisher
            .receive(on: DispatchQueue.global())
            .compactMap { $0 }
            .sink(receiveValue: onCaptureComplete)
            .store(in: &subscribers)

        cameraManager.sampleBufferPublisher
            .receive(on: DispatchQueue(label: "com.smileidentity.receivebuffer"))
            .compactMap { $0 }
            .sink(receiveValue: analyzeImage)
            .store(in: &subscribers)

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
                    if elapsedTime > documentAutoCaptureWaitTime && !self.isCapturing {
                        self.documentImageOrigin = DocumentImageOriginValue.cameraAutoCapture
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
        documentImageOrigin = DocumentImageOriginValue.gallery
        DispatchQueue.main.async {
            self.acknowledgedInstructions = true
            self.documentImageToConfirm = image
            self.showPhotoPicker = false
        }
    }

    /// Called when auto capture determines the image quality is sufficient OR when the user taps
    /// the manual capture button.
    func captureDocument() {
        if isCapturing {
            print("Already capturing. Skipping duplicate capture request")
            return
        }
        DispatchQueue.main.async {
            self.isCapturing = true
            self.directive = .capturing
        }
        documentImageOrigin = DocumentImageOriginValue.cameraManualCapture
        cameraManager.capturePhoto()
    }

    /// Called if the user declines the image in the capture confirmation dialog.
    func onRetry() {
        documentImageOrigin = nil
        resetDocumentCaptureMetadata()
        retryCount += 1
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
        let croppedImage = ImageUtils.cropImageToAspectRatio(
            imageData: image,
            aspectRatio: 1 / idAspectRatio
        )
        collectDocumentCaptureMetadata()
        DispatchQueue.main.async { [self] in
            documentImageToConfirm = croppedImage
            isCapturing = false
        }
    }

    private func resetDocumentCaptureMetadata() {
        switch side {
        case .front:
            metadata.removeMetadata(key: .documentFrontCaptureRetries)
            metadata.removeMetadata(key: .documentFrontCaptureDuration)
            metadata.removeMetadata(key: .documentFrontImageOrigin)
        case .back:
            metadata.removeMetadata(key: .documentBackCaptureRetries)
            metadata.removeMetadata(key: .documentBackCaptureDuration)
            metadata.removeMetadata(key: .documentBackImageOrigin)
        }
        metadata.removeMetadata(key: .deviceOrientation)
        metadata.removeMetadata(key: .deviceMovementDetected)
        hasRecordedOrientationAtCaptureStart = false
    }

    private func collectDocumentCaptureMetadata() {
        /*
         At the end of the capture, we record the device orientation and
         the capture duration
         */
        metadata.addMetadata(key: .deviceOrientation)
        switch side {
        case .front:
            metadata.addMetadata(
                key: .documentFrontCaptureDuration,
                value: captureDuration.elapsedTime().milliseconds()
            )
            metadata.addMetadata(key: .documentFrontCaptureRetries, value: retryCount)

            if let documentImageOrigin {
                metadata.addMetadata(
                    key: .documentFrontImageOrigin, value: documentImageOrigin.rawValue)
            }
        case .back:
            metadata.addMetadata(
                key: .documentBackCaptureDuration,
                value: captureDuration.elapsedTime().milliseconds()
            )
            metadata.addMetadata(key: .documentBackCaptureRetries, value: retryCount)

            if let documentImageOrigin {
                metadata.addMetadata(
                    key: .documentBackImageOrigin, value: documentImageOrigin.rawValue)
            }
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
        let now = Date().timeIntervalSince1970
        let elapsedTime = now - lastAnalysisTime

        /*
         At the start of the capture, we record the device orientation and start the capture
         duration timer.
         */
        if !hasRecordedOrientationAtCaptureStart {
            metadata.addMetadata(key: .deviceOrientation)
            hasRecordedOrientationAtCaptureStart = true
            captureDuration.startTime()
        }

        let enoughTimeHasPassed = elapsedTime > analysisSampleInterval
        if processingImage || isCapturing || !enoughTimeHasPassed {
            return
        }
        lastAnalysisTime = now
        processingImage = true
        let imageSize = CGSize(
            width: CVPixelBufferGetWidth(buffer),
            height: CVPixelBufferGetHeight(buffer)
        )
        
        let visionImage = uiImage(from: buffer)
        
        guard let visionImage = visionImage else {
            resetBoundingBox()
            processingImage = false
            return
        }
    
        objectDetector.process(visionImage) { objects, error in
            guard error == nil, let object = objects?.first else {
                self.resetBoundingBox()
                self.processingImage = false
                return
            }
            
            let boundingBox = object.frame
            let width = boundingBox.width
            let height = boundingBox.height
            let aspectRatio = width / height
        
            let quad = Quadrilateral(
                topLeft: boundingBox.origin,
                topRight: CGPoint(x: boundingBox.origin.x + boundingBox.width, y: boundingBox.origin.y),
                bottomRight: CGPoint(x: boundingBox.origin.x + boundingBox.width, y: boundingBox.origin.y + boundingBox.height),
                bottomLeft: CGPoint(x: boundingBox.origin.x, y: boundingBox.origin.y + boundingBox.height)
            )
        
            let isCentered = self.isRectCentered(
                detectedRect: quad,
                imageWidth: Double(imageSize.width),
                imageHeight: Double(imageSize.height)
            )
            
            let detectedAspectRatio = 1 / (aspectRatio ?? self.defaultAspectRatio)
            let isCorrectAspectRatio = self.isCorrectAspectRatio(
                detectedAspectRatio: detectedAspectRatio
            )
            let idAspectRatio = self.knownAspectRatio ?? detectedAspectRatio
            
            DispatchQueue.main.async { [self] in
                self.idAspectRatio = idAspectRatio
            }

            self.processingImage = false
            let areEdgesDetected = isCentered && isCorrectAspectRatio
            DispatchQueue.main.async { [self] in
                self.areEdgesDetected = areEdgesDetected
            }
        }
    }

    private func uiImage(from pixelBuffer: CVPixelBuffer) -> VisionImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()

        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
    
        let image = UIImage(cgImage: cgImage)
    
        let visionImage = VisionImage(image: image)
        visionImage.orientation = image.imageOrientation

        return visionImage
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

    func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
    }
}
