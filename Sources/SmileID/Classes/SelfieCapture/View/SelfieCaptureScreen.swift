import ARKit
import Foundation
import SwiftUI

struct SelfieCaptureScreen: View {
    let allowAgentMode: Bool
    @ObservedObject var viewModel: SelfieViewModel
    private let arView: ARView
    private let cameraView: CameraView

    init(allowAgentMode: Bool, viewModel: SelfieViewModel) {
        self.allowAgentMode = allowAgentMode
        self.viewModel = viewModel
        self.arView = ARView(delegate: viewModel)
        self.cameraView = CameraView(cameraManager: viewModel.cameraManager)
    }

    var body: some View {
        ZStack {
            let agentMode = viewModel.useBackCamera
            cameraView
                .onAppear { viewModel.cameraManager.switchCamera(to: agentMode ? .back : .front) }
                .onDisappear { viewModel.cameraManager.pauseSession() }
//            if ARFaceTrackingConfiguration.isSupported && !agentMode {
//                arView
//            }
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
    }
}
