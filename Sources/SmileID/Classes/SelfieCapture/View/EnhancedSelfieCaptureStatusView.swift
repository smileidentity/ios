import SwiftUI

struct EnhancedSelfieCaptureStatusView: View {
    var processingState: ProcessingState
    var errorMessage: String?
    var selfieImage: UIImage?
    let showAttribution: Bool

    var didTapCancel: () -> Void
    var didTapRetry: () -> Void

    private let faceShape = FaceShape()
    private let cameraContainerHeight: CGFloat = 480

    var body: some View {
        VStack {
            ZStack {
                if let selfieImage = selfieImage {
                    SelfiePreviewView(image: selfieImage)
                }
                RoundedRectangle(cornerRadius: 40)
                    .fill(SmileID.theme.tertiary.opacity(0.8))
                    .reverseMask(alignment: .top) {
                        faceShape
                            .frame(width: 250, height: 350)
                            .padding(.top, 50)
                    }
                    .frame(height: cameraContainerHeight)
                VStack {
                    Spacer()
                    UserInstructionsView(
                        instruction: processingState.title,
                        message: errorMessage
                    )
                }
                SubmissionStatusView(processState: processingState)
                    .padding(.bottom, 40)
            }
            .selfieCaptureFrameBackground(cameraContainerHeight)
            if showAttribution {
                Image(uiImage: SmileIDResourcesHelper.SmileEmblem)
            }

            Spacer()

            VStack {
                switch processingState {
                case .inProgress:
                    cancelButton
                case .success:
                    EmptyView()
                case .error:
                    SmileButton(title: "Confirmation.Retry") {
                        didTapRetry()
                    }
                    cancelButton
                }
            }
            .padding(.horizontal, 65)
        }
    }

    var cancelButton: some View {
        Button {
            didTapCancel()
        } label: {
            Text(SmileIDResourcesHelper.localizedString(for: "Action.Cancel"))
                .font(SmileID.theme.button)
                .foregroundColor(SmileID.theme.error)
        }
    }
}
