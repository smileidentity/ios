import Lottie
import SwiftUI

public struct SelfieCaptureScreenV2: View {
    @ObservedObject var viewModel: SelfieViewModelV2
    let showAttribution: Bool

    @Environment(\.presentationMode) private var presentationMode

    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Camera Preview Layer
                CameraView(cameraManager: viewModel.cameraManager, selfieViewModel: viewModel)

                // CameraPreview Mask
                Rectangle()
                    .fill(.white)
                    .reverseMask {
                        Circle()
                            .frame(width: 260, height: 260)
                    }

                FaceBoundingArea(
                    faceInBounds: viewModel.faceInBounds,
                    selfieCaptured: viewModel.selfieCaptured,
                    showGuideAnimation: viewModel.showGuideAnimation,
                    guideAnimation: viewModel.userInstruction?.guideAnimation
                )
                UserInstructionsView(viewModel: viewModel)
                if let currentLivenessTask = viewModel.livenessCheckManager.currentTask,
                    viewModel.faceInBounds {
                    LivenessGuidesView(
                        currentLivenessTask: currentLivenessTask,
                        topArcProgress: $viewModel.livenessCheckManager.lookUpProgress,
                        rightArcProgress: $viewModel.livenessCheckManager.lookRightProgress,
                        leftArcProgress: $viewModel.livenessCheckManager.lookLeftProgress
                    )
                }

                VStack {
                    Spacer()
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text(SmileIDResourcesHelper.localizedString(for: "Action.Cancel"))
                            .foregroundColor(SmileID.theme.accent)
                    }
                }
                .padding(.vertical, 40)

                NavigationLink(
                    destination: SelfieProcessingView(
                        model: viewModel,
                        didTapRetry: {
                            viewModel.showProcessingView = false
                        }
                    ),
                    isActive: $viewModel.showProcessingView,
                    label: { EmptyView()
                    }
                )
            }
            .edgesIgnoringSafeArea(.all)
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
