import Foundation
import SwiftUI

enum DocumentDirective: String {
    // todo: well lit and in focus directives
    case defaultInstructions = "Document.Directive.Default"
    case capturing = "Document.Directive.Capturing"
}

private let correctAspectRatioTolerance = 0.1

class DocumentCaptureViewModel: ObservableObject {
    // Initializer properties
    private let knownAspectRatio: Double?

    // Other properties
    private let defaultAspectRatio: Double
    private var isCapturing = false

    // UI properties
    // TODO: Mark these as @MainActor?
    @Published var acknowledgedInstructions = false
    @Published var directive: DocumentDirective = .defaultInstructions
    @Published var areEdgesDetected = false
    @Published var idAspectRatio = 1.0
    @Published var showManualCaptureButton = false
    @Published var documentImageToConfirm: URL?
    @Published var captureError: Error?
    @Published var showCaptureInProgress = false

    init(
        knownAspectRatio: Double? = nil
    ) {
        self.knownAspectRatio = knownAspectRatio
        defaultAspectRatio = knownAspectRatio ?? 1.0
        idAspectRatio = defaultAspectRatio

        // Show Manual Capture button after 10 seconds
        Timer.scheduledTimer(
            timeInterval: 10,
            target: self,
            selector: #selector(showManualCapture),
            userInfo: nil,
            repeats: false
        )
    }

    @objc func showManualCapture() {
        DispatchQueue.main.async {
            self.showManualCaptureButton = true
        }
    }

    func onTakePhotoClick() {
        acknowledgedInstructions = true
    }

    func onGallerySelectionClick() {
        // TODO
        print("TODO")
    }

    func onPhotoSelectedFromGallery(_ image: UIImage) {
        // TODO: Save image to documentImageToConfirm (write to file and return URL?) maybe the
        //  input param is wrong
    }

    /// Called when auto capture determines the image quality is sufficient or when the user taps
    /// the manual capture button.
    func captureDocument() {
        if (isCapturing) {
            print("Already capturing. Skipping duplicate capture request")
            return
        }
        isCapturing = true
        DispatchQueue.main.async {
            self.showCaptureInProgress = true
            self.directive = .capturing
        }
        // TODO: Take the picture
    }

    /// Called if the user declines the image in the capture confirmation dialog.
    func onRetry() {
        // TODO: Delete capture file
        isCapturing = false
        DispatchQueue.main.async {
            self.acknowledgedInstructions = false
            self.documentImageToConfirm = nil
            self.captureError = nil
            self.directive = .defaultInstructions
            self.areEdgesDetected = false
        }
    }

    // TODO: image analysis

    func resetBoundingBox() {
        DispatchQueue.main.async {
            self.areEdgesDetected = false
            self.idAspectRatio = self.defaultAspectRatio
        }
    }

    private func isCorrectAspectRatio(
        detectedAspectRatio: Double,
        tolerance: Double = correctAspectRatioTolerance
    ) -> Bool {
        let expectedAspectRatio = knownAspectRatio ?? defaultAspectRatio
        return abs(detectedAspectRatio - expectedAspectRatio) < tolerance
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
    let onConfirm: (URL) -> Void
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
        onConfirm: @escaping (URL) -> Void,
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
        if showInstructions && !viewModel.acknowledgedInstructions {
            DocumentCaptureInstructionsScreen(
                title: instructionsTitleText,
                subtitle: instructionsSubtitleText,
                showAttribution: showAttribution,
                allowPhotoFromGallery: allowGallerySelection,
                showSkipButton: showSkipButton,
                onSkip: onSkip,
                onInstructionsAcknowledgedSelectFromGallery: viewModel.onGallerySelectionClick,
                onInstructionsAcknowledgedTakePhoto: viewModel.onTakePhotoClick
            )
        } else if let imageToConfirm = viewModel.documentImageToConfirm {
            // TODO: Image Confirmation Dialog
        } else {
            CaptureScreenContent(
                title: captureTitleText,
                subtitle: SmileIDResourcesHelper.localizedString(for: viewModel.directive.rawValue),
                idAspectRatio: viewModel.idAspectRatio,
                areEdgesDetected: viewModel.areEdgesDetected,
                showCaptureInProgress: viewModel.showCaptureInProgress,
                showManualCaptureButton: viewModel.showManualCaptureButton,
                onCaptureClick: viewModel.captureDocument
            )
            // TODO: Capture Screen
        }
    }
}

private struct DocumentCaptureInstructionsScreen: View {
    let title: String
    let subtitle: String
    let showAttribution: Bool
    let allowPhotoFromGallery: Bool
    let showSkipButton: Bool
    let onSkip: () -> Void
    let onInstructionsAcknowledgedSelectFromGallery: () -> Void
    let onInstructionsAcknowledgedTakePhoto: () -> Void

    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    Image(uiImage: SmileIDResourcesHelper.InstructionsHeaderDocumentIcon)
                        .padding(.bottom, 24)
                    VStack(spacing: 16) {
                        Text(title)
                            .multilineTextAlignment(.center)
                            .font(SmileID.theme.header1)
                            .foregroundColor(SmileID.theme.accent)
                            .lineSpacing(0.98)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(subtitle)
                            .multilineTextAlignment(.center)
                            .font(SmileID.theme.header5)
                            .foregroundColor(SmileID.theme.tertiary)
                            .lineSpacing(1.3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                        .padding(.bottom, 16)

                    VStack(alignment: .leading, spacing: 32) {
                        HStack(spacing: 16) {
                            Image(uiImage: SmileIDResourcesHelper.image(Constants.ImageName.light)!)
                            VStack(alignment: .leading, spacing: 8) {
                                Text(SmileIDResourcesHelper.localizedString(for: "Instructions.GoodLight"))
                                    .font(SmileID.theme.header4)
                                    .foregroundColor(SmileID.theme.accent)
                                Text(SmileIDResourcesHelper.localizedString(for: "Instructions.GoodLightBody"))
                                    .multilineTextAlignment(.leading)
                                    .font(SmileID.theme.header5)
                                    .foregroundColor(SmileID.theme.tertiary)
                                    .lineSpacing(1.3)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        HStack(spacing: 16) {
                            Image(uiImage: SmileIDResourcesHelper.image(Constants.ImageName.clearImage)!)
                            VStack(alignment: .leading, spacing: 8) {
                                Text(SmileIDResourcesHelper.localizedString(for: "Instructions.ClearImage"))
                                    .font(SmileID.theme.header4)
                                    .foregroundColor(SmileID.theme.accent)
                                Text(SmileIDResourcesHelper.localizedString(for: "Instructions.ClearImageBody"))
                                    .multilineTextAlignment(.leading)
                                    .font(SmileID.theme.header5)
                                    .foregroundColor(SmileID.theme.tertiary)
                                    .lineSpacing(1.3)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
            VStack(spacing: 4) {
                if showSkipButton {
                    Button(
                        action: onSkip,
                        label: {
                            Text(SmileIDResourcesHelper.localizedString(for: "Action.Skip"))
                                .multilineTextAlignment(.center)
                                .font(SmileID.theme.button)
                                .foregroundColor(SmileID.theme.tertiary.opacity(0.8))
                        }
                    )
                        .frame(height: 48)
                }

                SmileButton(
                    title: "Action.TakePhoto",
                    clicked: onInstructionsAcknowledgedTakePhoto
                )

                if allowPhotoFromGallery {
                    SmileButton(
                        style: .alternate,
                        title: "Action.UploadPhoto",
                        clicked: onInstructionsAcknowledgedSelectFromGallery
                    )
                }
                if showAttribution {
                    Image(uiImage: SmileIDResourcesHelper.SmileEmblem)
                }
            }
        }
            .padding(EdgeInsets(
                top: 0,
                leading: 24,
                bottom: 16,
                trailing: 24
            ))
    }
}

struct CaptureScreenContent: View {
    let title: String
    let subtitle: String
    let idAspectRatio: Double
    let areEdgesDetected: Bool
    let showCaptureInProgress: Bool
    let showManualCaptureButton: Bool
    let onCaptureClick: () -> Void
    // let rectangleDelegate: RectangleDetectionDelegate

    // private var currentBuffer: CVPixelBuffer? = nil
    // private let textDetector = TextDetector()
    // private var cameraManager = CameraManager(orientation: .portrait)

    var body: some View {
        let cameraManager = CameraManager(orientation: .portrait)
        VStack(alignment: .center, spacing: 16) {
            ZStack {
                CameraView(cameraManager: cameraManager).onAppear {
                    cameraManager.switchCamera(to: .back)
                    cameraManager.sampleBufferPublisher
                        .receive(on: DispatchQueue(label: "com.smileidentity.receivebuffer"))
                        .compactMap { $0 }
                        .sink(receiveValue: { [self] buffer in
                            // TODO: Rectangle detection
                        })
                }
                let borderColor = areEdgesDetected ? SmileID.theme.success : .gray
                DocumentOverlayView(
                    aspectRatio: idAspectRatio,
                    borderColor: borderColor.uiColor()
                )
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack(alignment: .center, spacing: 16) {
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
                ZStack {
                    if showCaptureInProgress {
                        ActivityIndicator(isAnimating: true).padding()
                    } else if showManualCaptureButton {
                        CaptureButton(action: onCaptureClick).padding()
                    }
                    // By using a fixed size here, we ensure the UI doesn't move around when the
                    // manual capture button becomes visible
                }.frame(height: 64)
                Spacer()
            }
        }
            // .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
