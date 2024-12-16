import SwiftUI

public struct EnhancedSelfieCaptureScreen: View {
    @Backport.StateObject var viewModel: EnhancedSmartSelfieViewModel
    let showAttribution: Bool

    private let faceShape = FaceShape()
    private(set) var originalBrightness = UIScreen.main.brightness
    private let cameraContainerHeight: CGFloat = 480

    public init(
        viewModel: EnhancedSmartSelfieViewModel,
        showAttribution: Bool
    ) {
        self._viewModel = Backport.StateObject(wrappedValue: viewModel)
        self.showAttribution = showAttribution
    }

    public var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 10) {
                switch viewModel.selfieCaptureState {
                case .capturingSelfie:
                    ZStack {
                        CameraView(
                            cameraManager: viewModel.cameraManager,
                            selfieViewModel: viewModel
                        )
                        .cornerRadius(40)
                        .frame(height: cameraContainerHeight)

                        RoundedRectangle(cornerRadius: 40)
                            .fill(SmileID.theme.tertiary.opacity(0.8))
                            .reverseMask(alignment: .top) {
                                faceShape
                                    .frame(width: 250, height: 350)
                                    .padding(.top, 50)
                            }
                            .frame(height: cameraContainerHeight)
                        VStack {
                            ZStack {
                                FaceBoundingArea(
                                    faceInBounds: viewModel.faceInBounds,
                                    selfieCaptured: viewModel.selfieCaptured,
                                    showGuideAnimation: viewModel.showGuideAnimation,
                                    guideAnimation: viewModel.userInstruction?.guideAnimation
                                )
                                if let currentLivenessTask = viewModel.livenessCheckManager.currentTask,
                                    viewModel.faceInBounds {
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
                            if let userInstruction = viewModel.userInstruction {
                                UserInstructionsView(
                                    instruction: userInstruction.instruction
                                )
                            }
                        }
                    }
                    .selfieCaptureFrameBackground(cameraContainerHeight)
                    if showAttribution {
                        Image(uiImage: SmileIDResourcesHelper.SmileEmblem)
                    }
                case let .processing(processingState):
                    ZStack {
                        if let selfieImage = viewModel.selfieImage {
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
                                message: processingState == .error ? getErrorSubtitle(
                                    errorMessageRes: viewModel.errorMessageRes,
                                    errorMessage: viewModel.errorMessage
                                ) : nil
                            )
                        }
                        SubmissionStatusView(processState: processingState)
                            .padding(.bottom, 40)
                    }
                    .selfieCaptureFrameBackground(cameraContainerHeight)
                    if showAttribution {
                        Image(uiImage: SmileIDResourcesHelper.SmileEmblem)
                    }
                }
                Spacer()
                SelfieActionsView(
                    captureState: viewModel.selfieCaptureState,
                    retryAction: { viewModel.perform(action: .retryJobSubmission) },
                    cancelAction: {
                        viewModel.perform(action: .cancelSelfieCapture)
                    }
                )
            }
            .padding(.vertical, 20)
            .navigationBarHidden(true)
            .onAppear {
                UIScreen.main.brightness = 1
                UIApplication.shared.isIdleTimerDisabled = true
                viewModel.perform(action: .windowSizeDetected(proxy.size, proxy.safeAreaInsets))
                viewModel.perform(action: .onViewAppear)
            }
            .onDisappear {
                UIScreen.main.brightness = originalBrightness
                UIApplication.shared.isIdleTimerDisabled = false
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

extension View {
    func selfieCaptureFrameBackground(_ containerHeight: CGFloat) -> some View {
        self
            .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
            .frame(height: containerHeight)
            .padding(.horizontal)
    }
}
