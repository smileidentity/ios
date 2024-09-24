import Lottie
import SwiftUI

public struct SelfieCaptureScreenV2: View {
    @ObservedObject var viewModel: SelfieViewModelV2
    let showAttribution: Bool
    @State private var showImages: Bool = false

    @Environment(\.presentationMode) private var presentationMode

    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Camera Preview Layer
                CameraView(cameraManager: viewModel.cameraManager, selfieViewModel: viewModel)
                    .onAppear {
                        viewModel.cameraManager.switchCamera(to: .front)
                    }

                // CameraPreview Mask
                Rectangle()
                    .fill(.white)
                    .reverseMask {
                        Circle()
                            .frame(width: 260, height: 260)
                    }

                FaceBoundingArea(viewModel: viewModel)
                    .hidden()
                UserInstructionsView(viewModel: viewModel)
                LivenessGuidesView(
                    topArcProgress: $viewModel.activeLiveness.lookUpProgress,
                    rightArcProgress: $viewModel.activeLiveness.lookRightProgress,
                    leftArcProgress: $viewModel.activeLiveness.lookLeftProgress
                )

                VStack {
                    Spacer()
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text(SmileIDResourcesHelper.localizedString(for: "Action.Cancel"))
                            .foregroundColor(SmileID.theme.accent)
                    }
                }
                .padding(.bottom, 40)
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
                        Text(SmileIDResourcesHelper.localizedString(for: "Camera.Unauthorized.PrimaryAction")),
                        action: {
                            viewModel.perform(action: .openApplicationSettings)
                        }
                    ),
                    secondaryButton: .cancel()
                )
            }
            .sheet(isPresented: $showImages) {
                CapturedImagesView(model: viewModel)
            }
        }
    }
}
