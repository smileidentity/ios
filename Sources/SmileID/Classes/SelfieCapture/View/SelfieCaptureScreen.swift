import ARKit
import Foundation
import SwiftUI

/// The actual selfie capture screen, which shows the camera preview and the progress indicator
public struct SelfieCaptureScreen: View {
    let allowAgentMode: Bool
    @ObservedObject var viewModel: SelfieViewModel

    public init(allowAgentMode: Bool, viewModel: SelfieViewModel) {
        self.allowAgentMode = allowAgentMode
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            let agentMode = viewModel.useBackCamera
            if ARFaceTrackingConfiguration.isSupported && !agentMode {
                ARView(delegate: viewModel)
            } else {
                CameraView(cameraManager: viewModel.cameraManager)
                    .onAppear {
                        viewModel.cameraManager.switchCamera(to: agentMode ? .back : .front)
                    }
            }
            FaceShapedProgressIndicator(progress: viewModel.captureProgress)
            VStack(spacing: 24) {
                Spacer()
                Text(SmileIDResourcesHelper.localizedString(for: viewModel.directive))
                    .multilineTextAlignment(.center)
                    .foregroundColor(SmileID.theme.accent)
                    .font(SmileID.theme.header4)
                    .transition(.slide)

                if allowAgentMode {
                    let textColor = agentMode ? SmileID.theme.backgroundMain : SmileID.theme.accent
                    let bgColor = agentMode ? SmileID.theme.accent : SmileID.theme.backgroundMain
                    Toggle(isOn: $viewModel.useBackCamera) {
                        Text(SmileIDResourcesHelper.localizedString(for: "Camera.AgentMode"))
                            .font(SmileID.theme.header4)
                            .foregroundColor(textColor)
                    }
                        .padding(10)
                        .background(bgColor)
                        .cornerRadius(25)
                        .shadow(radius: 25)
                        .animation(.default)
                        .frame(maxWidth: 200)
                }
            }
                .padding(24)
        }
        .alert(item: $viewModel.alert) { alert in
            Alert(
                title: Text("App name Needs Access to Your Camera"),
                message: Text("The camera permission is required to complete the verification process"),
                primaryButton: .cancel(),
                secondaryButton: .default(
                    Text("Open Settings"),
                    action: {
                        viewModel.openSettings()
                    }
                )
            )
        }
    }
}
