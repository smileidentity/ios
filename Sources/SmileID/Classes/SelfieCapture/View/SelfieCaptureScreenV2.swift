import SwiftUI
import Lottie

public struct SelfieCaptureScreenV2: View {
    @ObservedObject var viewModel: SelfieViewModelV2
    let showAttribution: Bool

    public var body: some View {
        ZStack {
            CameraView(cameraManager: viewModel.cameraManager, selfieViewModel: viewModel)
                .onAppear {
                    viewModel.cameraManager.switchCamera(to: .front)
                }
//            VStack {
//                ZStack {
//                    CameraView(cameraManager: viewModel.cameraManager, selfieViewModel: viewModel)
//                        .onAppear {
//                            viewModel.cameraManager.switchCamera(to: .front)
//                        }
//                    LayoutGuideView(
//                        layoutGuideFrame: viewModel.faceLayoutGuideFrame
//                    )
//                }
//                .frame(width: viewModel.faceLayoutGuideFrame.width, height: viewModel.faceLayoutGuideFrame.height)
//                .padding(.top, 80)
//                Text(SmileIDResourcesHelper.localizedString(for: viewModel.directive))
//                    .font(SmileID.theme.header4)
//                    .foregroundColor(.primary)
//                    .padding(.bottom)
//                    .padding(.horizontal)
//                Spacer()
//                if showAttribution {
//                    Image(uiImage: SmileIDResourcesHelper.SmileEmblem)
//                }
//            }
            if viewModel.debugEnabled {
                FaceBoundingBoxView(model: viewModel)
            }
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
    }

    // swiftlint:disable identifier_name
    @ViewBuilder func DebugView() -> some View {
        ZStack {
            FaceBoundingBoxView(model: viewModel)
            VStack(spacing: 0) {
                Spacer()
                // Text("Progress: \(viewModel.captureProgress)")
                Text("\(viewModel.isFaceInFrame ? "Face in Frame" : "Face out of Frame")")
                Text("Yaw: \(viewModel.yawValue)")
                Text("Row: \(viewModel.rollValue)")
                Text("Pitch: \(viewModel.pitchValue)")
                Text("Quality: \(viewModel.faceQualityValue)")
                Text("Selfie Quality Model")
                    .padding(.top, 10)
                Text("Fail: \(viewModel.selfieQualityValue.failed) | Pass: \(viewModel.selfieQualityValue.passed)")
                    .font(.subheadline.weight(.medium))
                    .padding(5)
                    .background(Color.yellow)
                    .clipShape(.rect(cornerRadius: 5))
                    .padding(.bottom, 10)
                switch viewModel.faceDirection {
                case .left:
                    Text("Looking Left")
                case .right:
                    Text("Looking Right")
                case .none:
                    Text("Looking Straight")
                }
            }
            .foregroundColor(.primary)
            .padding(.bottom, 40)
        }
    }

    // swiftlint:disable identifier_name
    @ViewBuilder func CameraOverlayView() -> some View {
        VStack {
            HStack {
                Text(SmileIDResourcesHelper.localizedString(for: viewModel.directive))
                    .font(SmileID.theme.header2)
                    .foregroundColor(.primary)
                    .padding(.bottom)
            }
            .background(Color.black)
            Spacer()
            HStack {
                Button {
                    viewModel.perform(action: .toggleDebugMode)
                } label: {
                    Image(systemName: "ladybug")
                        .font(.title)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
