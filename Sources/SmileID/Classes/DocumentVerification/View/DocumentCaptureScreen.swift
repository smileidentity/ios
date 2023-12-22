import SwiftUI

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
                onRetake: viewModel.onRetry,
                scaleFactor: 1.0
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
