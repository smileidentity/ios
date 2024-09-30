import Lottie
import SwiftUI

public struct SelfieCaptureScreenV2: View {
    @ObservedObject var viewModel: SelfieViewModelV2
    let showAttribution: Bool

    @Environment(\.presentationMode) private var presentationMode

    @State private var progress1: CGFloat = 0.3
    @State private var progress2: CGFloat = 0.8
    @State private var progress3: CGFloat = 0.5

    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Camera Preview Layer
                CameraView(cameraManager: viewModel.cameraManager, selfieViewModel: viewModel)
                    .onAppear {
                        viewModel.cameraManager.switchCamera(to: .front)
                        viewModel.perform(action: .setupDelayTimer)
                    }

                // CameraPreview Mask
                Rectangle()
                    .fill(.white)
                    .reverseMask {
                        Circle()
                            .frame(width: 260, height: 260)
                    }

                FaceBoundingArea(
                    isAcceptableBounds: viewModel.isAcceptableBounds,
                    showGuideAnimation: viewModel.showGuideAnimation,
                    guideAnimation: viewModel.guideAnimation
                )
                UserInstructionsView(viewModel: viewModel)
                LivenessGuidesView(
                    topArcProgress: $viewModel.activeLiveness.lookUpProgress,
                    rightArcProgress: $viewModel.activeLiveness.lookRightProgress,
                    leftArcProgress: $viewModel.activeLiveness.lookLeftProgress
                )

                VStack {
                    Spacer()
                    Text("\(viewModel.elapsedDelay)")
                        .font(.title)
                    Button {
                        viewModel.cameraManager.pauseSession()
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text(SmileIDResourcesHelper.localizedString(for: "Action.Cancel"))
                            .foregroundColor(SmileID.theme.accent)
                    }
                }
                .padding(.vertical, 40)
            }
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                viewModel.perform(action: .windowSizeDetected(proxy.frame(in: .global)))
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
            .sheet(isPresented: $viewModel.showImages) {
                CapturedImagesView(model: viewModel)
            }
        }
    }
}
