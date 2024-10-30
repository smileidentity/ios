import Lottie
import SwiftUI

public struct SelfieCaptureScreenV2: View {
    @ObservedObject var viewModel: SelfieViewModelV2
    let showAttribution: Bool

    @Environment(\.modalMode) private var modalMode

    public var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 10) {
                ZStack {
                    CameraView(
                        cameraManager: viewModel.cameraManager,
                        selfieViewModel: viewModel
                    )
                    .cornerRadius(40)

                    if let selfieImage = viewModel.selfieImage,
                        viewModel.processingState != nil {
                        SelfiePreviewView(image: selfieImage)
                    }

                    RoundedRectangle(cornerRadius: 40)
                        .fill(SmileID.theme.tertiary.opacity(0.8))
                        .reverseMask(alignment: .top) {
                            FaceShape()
                                .frame(width: 250, height: 350)
                                .padding(.top, 60)
                        }
                    VStack {
                        ZStack {
                            FaceBoundingArea(
                                faceInBounds: viewModel.faceInBounds,
                                selfieCaptured: viewModel.selfieCaptured,
                                showGuideAnimation: viewModel.showGuideAnimation,
                                guideAnimation: viewModel.userInstruction?.guideAnimation
                            )
                            if let currentLivenessTask = viewModel.livenessCheckManager.currentTask {
                                LivenessGuidesView(
                                    currentLivenessTask: currentLivenessTask,
                                    topArcProgress: $viewModel.livenessCheckManager.lookUpProgress,
                                    rightArcProgress: $viewModel.livenessCheckManager.lookRightProgress,
                                    leftArcProgress: $viewModel.livenessCheckManager.lookLeftProgress
                                )
                            }
                        }
                        .padding(.top, 50)
                        Spacer()
                        UserInstructionsView(
                            instruction: viewModel.userInstruction?.instruction ?? ""
                        )
                        Spacer()
                    }

                    if let processingState = viewModel.processingState {
                        SubmissionStatusView(processState: processingState)
                            .padding(.bottom, 40)
                    }
                }
                .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
                .frame(height: 520)
                .padding(.horizontal)
                .padding(.top, 40)

                if showAttribution {
                    Image(uiImage: SmileIDResourcesHelper.SmileEmblem)
                }

                Spacer()

                SelfieActionsView(
                    processingState: viewModel.processingState,
                    retryAction: {
                        viewModel.perform(action: .retryJobSubmission)
                    },
                    cancelAction: {
                        modalMode.wrappedValue = false
                        viewModel.perform(action: .jobProcessingDone)
                    }
                )
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.perform(action: .windowSizeDetected(proxy.size))
                viewModel.perform(action: .onViewAppear)
            }
            .onDisappear {
                viewModel.cameraManager.pauseSession()
            }
            .alert(item: $viewModel.unauthorizedAlert) { alert in
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.message ?? ""),
                    primaryButton: .default(
                        Text(
                            SmileIDResourcesHelper.localizedString(
                                for: "Camera.Unauthorized.PrimaryAction")),
                        action: {
                            viewModel.perform(action: .openApplicationSettings)
                        }
                    ),
                    secondaryButton: .cancel()
                )
            }
        }
    }
}
