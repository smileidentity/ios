import Foundation
import SwiftUI

public struct OrchestratedSelfieCaptureScreen: View {
    public let userId: String
    public let jobId: String
    public let isEnroll: Bool
    // TODO: pass allowNewEnroll through
    public let allowNewEnroll: Bool
    public let allowAgentMode: Bool
    public let showAttribution: Bool
    public let showInstructions: Bool
    public let extraPartnerParams: [String: String]
    // TODO: make use of skipApiSubmission
    public let skipApiSubmission: Bool
    public let onResult: SmartSelfieResultDelegate
    @ObservedObject var viewModel: SelfieViewModel

    @State private var acknowledgedInstructions = false
    private var originalBrightness = UIScreen.main.brightness
    
    public init(
        userId: String,
        jobId: String,
        isEnroll: Bool,
        allowNewEnroll: Bool,
        allowAgentMode: Bool,
        showAttribution: Bool,
        showInstructions: Bool,
        extraPartnerParams: [String: String],
        skipApiSubmission: Bool,
        onResult: SmartSelfieResultDelegate
    ) {
        self.userId = userId
        self.jobId = jobId
        self.isEnroll = isEnroll
        self.allowNewEnroll = allowNewEnroll
        self.allowAgentMode = allowAgentMode
        self.showAttribution = showAttribution
        self.showInstructions = showInstructions
        self.extraPartnerParams = extraPartnerParams
        self.skipApiSubmission = skipApiSubmission
        self.onResult = onResult
        self.viewModel = SelfieViewModel()
        
    }

    public var body: some View {
        if showInstructions && !acknowledgedInstructions {
            SmartSelfieInstructionsScreen(showAttribution: showAttribution) {
                acknowledgedInstructions = true
            }
        } else if let processingState = viewModel.processingState {
            ProcessingScreen(
                processingState: processingState,
                inProgressTitle: SmileIDResourcesHelper.localizedString(
                    for: "Confirmation.ProcessingSelfie"
                ),
                inProgressSubtitle: SmileIDResourcesHelper.localizedString(
                    for: "Confirmation.Time"
                ),
                inProgressIcon: SmileIDResourcesHelper.FaceOutline,
                successTitle: SmileIDResourcesHelper.localizedString(
                    for: "Confirmation.SelfieCaptureComplete"
                ),
                successSubtitle: SmileIDResourcesHelper.localizedString(
                    for: "Confirmation.SuccessBody"
                ),
                successIcon: SmileIDResourcesHelper.CheckBold,
                errorTitle: SmileIDResourcesHelper.localizedString(
                    for: "Confirmation.Failure"
                ),
                errorSubtitle: SmileIDResourcesHelper.localizedString(
                    for: "Confirmation.FailureReason"
                ),
                errorIcon: SmileIDResourcesHelper.Scan,
                continueButtonText: SmileIDResourcesHelper.localizedString(
                    for: "Confirmation.Continue"
                ),
                onContinue: { viewModel.onFinished(callback: onResult) },
                retryButtonText: SmileIDResourcesHelper.localizedString(
                    for: "Confirmation.Retry"
                ),
                onRetry: viewModel.onRetry,
                closeButtonText: SmileIDResourcesHelper.localizedString(
                    for: "Confirmation.Close"
                ),
                onClose: { viewModel.onFinished(callback: onResult) }
            )
        } else if let selfieToConfirm = viewModel.selfieToConfirm {
            ImageCaptureConfirmationDialog(
                title: SmileIDResourcesHelper.localizedString(
                    for: "Confirmation.GoodSelfie"
                ),
                subtitle: SmileIDResourcesHelper.localizedString(
                    for: "Confirmation.FaceClear"
                ),
                image: UIImage(data: selfieToConfirm)!,
                confirmationButtonText: SmileIDResourcesHelper.localizedString(
                    for: "Confirmation.YesUse"
                ),
                onConfirm: viewModel.submitJob,
                retakeButtonText: SmileIDResourcesHelper.localizedString(
                    for: "Confirmation.Retake"
                ),
                onRetake: viewModel.onSelfieRejected,
                scaleFactor: 1.25
            )
        } else {
            SelfieCaptureScreen(
                allowAgentMode: allowAgentMode,
                viewModel: viewModel
            )
                .onAppear { UIScreen.main.brightness = 1 }
                .onDisappear { UIScreen.main.brightness = originalBrightness }
        }
    }
}

struct SmartSelfieInstructionsScreen: View {
    let showAttribution: Bool
    let onInstructionsAcknowledged: () -> Void

    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    Image(uiImage: SmileIDResourcesHelper.InstructionsHeaderIcon)
                        .padding(24)
                    VStack(spacing: 16) {
                        Text(SmileIDResourcesHelper.localizedString(for: "Instructions.Header"))
                            .multilineTextAlignment(.center)
                            .font(SmileID.theme.header1)
                            .foregroundColor(SmileID.theme.accent)
                            .lineSpacing(0.98)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(SmileIDResourcesHelper.localizedString(for: "Instructions.Callout"))
                            .multilineTextAlignment(.center)
                            .font(SmileID.theme.header5)
                            .foregroundColor(SmileID.theme.tertiary)
                            .lineSpacing(1.3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                        .padding(.bottom, 48)

                    VStack(alignment: .leading, spacing: 32) {
                        HStack(spacing: 16) {
                            Image(uiImage: SmileIDResourcesHelper.Light)
                            VStack(alignment: .leading, spacing: 8) {
                                Text(SmileIDResourcesHelper.localizedString(
                                    for: "Instructions.GoodLight"
                                ))
                                    .font(SmileID.theme.header4)
                                    .foregroundColor(SmileID.theme.accent)
                                Text(SmileIDResourcesHelper.localizedString(
                                    for: "Instructions.GoodLightBody"
                                ))
                                    .multilineTextAlignment(.leading)
                                    .font(SmileID.theme.header5)
                                    .foregroundColor(SmileID.theme.tertiary)
                                    .lineSpacing(1.3)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        HStack(spacing: 16) {
                            Image(uiImage: SmileIDResourcesHelper.ClearImage)
                            VStack(alignment: .leading, spacing: 8) {
                                Text(SmileIDResourcesHelper.localizedString(
                                    for: "Instructions.ClearImage"
                                ))
                                    .font(SmileID.theme.header4)
                                    .foregroundColor(SmileID.theme.accent)
                                Text(SmileIDResourcesHelper.localizedString(
                                    for: "Instructions.ClearImageBody"
                                ))
                                    .multilineTextAlignment(.leading)
                                    .font(SmileID.theme.header5)
                                    .foregroundColor(SmileID.theme.tertiary)
                                    .lineSpacing(1.3)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        HStack(spacing: 16) {
                            Image(uiImage: SmileIDResourcesHelper.Face)
                            VStack(alignment: .leading, spacing: 8) {
                                Text(SmileIDResourcesHelper.localizedString(
                                    for: "Instructions.RemoveObstructions"
                                ))
                                    .font(SmileID.theme.header4)
                                    .foregroundColor(SmileID.theme.accent)
                                Text(SmileIDResourcesHelper.localizedString(
                                    for: "Instructions.RemoveObstructionsBody"
                                ))
                                    .multilineTextAlignment(.leading)
                                    .font(SmileID.theme.header5)
                                    .foregroundColor(SmileID.theme.tertiary)
                                    .lineSpacing(1.3)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }

            VStack(spacing: 8) {
                SmileButton(
                    title: "Action.TakePhoto",
                    clicked: onInstructionsAcknowledged
                )

                if showAttribution {
                    Image(uiImage: SmileIDResourcesHelper.SmileEmblem)
                }
            }
        }
            .padding(.horizontal, 16)
    }
}

struct SelfieCaptureScreen: View {
    let allowAgentMode: Bool
    @ObservedObject var viewModel: SelfieViewModel

    var body: some View {
        ZStack {
            // TODO: ARView?
            CameraView(cameraManager: viewModel.cameraManager)
                .onAppear { viewModel.cameraManager.switchCamera(to: .front) }
                .onDisappear { viewModel.cameraManager.pauseSession() }
            FaceShapedProgressIndicator(progress: 0.5)
            VStack(spacing: 24) {
                Spacer()
                Text(SmileIDResourcesHelper.localizedString(for: viewModel.directive))
                    .multilineTextAlignment(.center)
                    .foregroundColor(SmileID.theme.accent)
                    .font(SmileID.theme.header4)
                    .transition(.slide)

                if allowAgentMode {
                    let agentMode = viewModel.useBackCamera
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

struct FaceShapedProgressIndicator: View {
    let progress: Double
    private let strokeWidth = 10
    private let faceShape = FaceShape().scale(x: 0.8, y: 0.6).offset(y: -50)
    private let bgColor = Color.white.opacity(0.8)
    var body: some View {
        bgColor
            .cutout(faceShape)
            .overlay(faceShape.stroke(SmileID.theme.accent.opacity(0.4), lineWidth: 10))
            .overlay(
                // TODO: Make this fill from bottom to top, symmetrically
                faceShape
                    .trim(from: 0, to: progress)
                    .stroke(
                        SmileID.theme.success,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .animation(.easeInOut, value: progress)
            )
    }
}

class SelfieViewModel: ObservableObject {
    var cameraManager = CameraManager(orientation: .portrait)

    // UI Properties
    @Published var directive: String = "Instructions.Unstable"
    @Published var processingState: ProcessingState?
    @Published var selfieToConfirm: Data?
    @Published var useBackCamera = false {
        // This is toggled by a Binding
        didSet { switchCamera() }
    }

    func switchCamera() {
        self.cameraManager.switchCamera(to: useBackCamera ? .back : .front)
    }

    func onSelfieRejected() {
        // TODO
    }

    func onRetry() {
        // TODO
    }

    func submitJob() {
        // TODO
    }

    func onFinished(callback: SmartSelfieResultDelegate) {
        // TODO
    }
}
