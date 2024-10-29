import Lottie
import SwiftUI

public struct SelfieCaptureScreenV2: View {
    @ObservedObject var viewModel: SelfieViewModelV2
    let showAttribution: Bool

    @Environment(\.modalMode) private var modalMode

    public var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 10) {
                HStack {
                    Spacer()
                    Button {
                        modalMode.wrappedValue = false
                        viewModel.perform(action: .jobProcessingDone)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                    }
                }
                .padding(.horizontal, 20)

                ZStack {
                    CameraView(
                        cameraManager: viewModel.cameraManager,
                        selfieViewModel: viewModel
                    )
                    .cornerRadius(40)

                    RoundedRectangle(cornerRadius: 40)
                        .fill(SmileID.theme.tertiary.opacity(0.8))
                        .reverseMask(alignment: .top) {
                            FaceShape()
                                .frame(width: 250, height: 350)
                                .padding(.top, 60)
                        }
                    VStack {
                        ZStack {
                            FaceShape()
                                .stroke(
                                    SmileID.theme.success,
                                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                )
                                .frame(width: 270, height: 370)
                                .opacity(0)
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
                        Text(SmileIDResourcesHelper.localizedString(for: viewModel.userInstruction?.instruction ?? ""))
                            .font(SmileID.theme.header2)
                            .foregroundColor(SmileID.theme.onDark)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .minimumScaleFactor(0.8)
                            .padding(20)
                        Spacer()
                    }
                }
                .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
                .padding(.horizontal)
                .frame(height: 520)
                .fixedSize(horizontal: false, vertical: true)

                if showAttribution {
                    Image(uiImage: SmileIDResourcesHelper.SmileEmblem)
                }

                Spacer()

                VStack {
                    SmileButton(title: "Confirmation.Retry") {
                        viewModel.perform(action: .retryJobSubmission)
                    }
                    Button {
                        modalMode.wrappedValue = false
                        viewModel.perform(action: .jobProcessingDone)
                    } label: {
                        Text(SmileIDResourcesHelper.localizedString(for: "Action.Cancel"))
                            .font(SmileID.theme.button)
                            .foregroundColor(SmileID.theme.error)
                    }
                    .padding(.top)
                }
                .padding(.horizontal, 65)
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
