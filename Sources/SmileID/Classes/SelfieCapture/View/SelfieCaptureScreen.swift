import ARKit
import Foundation
import SwiftUI

/// The actual selfie capture screen, which shows the camera preview and the progress indicator
public struct SelfieCaptureScreen: View {
    @Backport.StateObject var viewModel: SelfieViewModel
    let allowAgentMode: Bool

    public init(viewModel: SelfieViewModel, allowAgentMode: Bool) {
        self._viewModel = Backport.StateObject(wrappedValue: viewModel)
        self.allowAgentMode = allowAgentMode
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
        .preferredColorScheme(.light)
        .alert(item: $viewModel.unauthorizedAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message ?? ""),
                primaryButton: .default(
                    Text(SmileIDResourcesHelper.localizedString(for: "Camera.Unauthorized.PrimaryAction")),
                    action: {
                        viewModel.openSettings()
                    }
                ),
                secondaryButton: .cancel()
            )
        }
    }
}
