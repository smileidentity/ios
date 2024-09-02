import SwiftUI
import Lottie

public struct SelfieCaptureScreenV2: View {
    @ObservedObject var viewModel: SelfieViewModelV2
    let showAttribution: Bool
    @State private var showImages: Bool = false

    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                CameraView(cameraManager: viewModel.cameraManager, selfieViewModel: viewModel)
                    .onAppear {
                        viewModel.cameraManager.switchCamera(to: .front)
                    }

                Rectangle()
                    .fill(.white)
                    .reverseMask {
                        Circle()
                            .frame(width: 260, height: 260)
                    }

                // Face Bounds Indicator
                Circle()
                    .stroke(.red, lineWidth: 10)
                    .frame(width: 275, height: 275)
                    .hidden()

                // Container for Lottie Animation
                Circle()
                    .fill(.black.opacity(0.7))
                    .frame(width: 260, height: 260)
                    .overlay(
                        Text("Lottie animation\ngoes here.")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    )

                // Liveness Guides
                ZStack {
                    // Look Up Guides
                    Circle()
                        .trim(from: 0.85, to: 1.0)
                        .rotation(.degrees(-65))
                        .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                        .foregroundColor(.gray.opacity(0.3))
                        .frame(width: 300, height: 300)
                    Circle()
                        .trim(from: 0.85, to: 0.95)
                        .rotation(.degrees(-65))
                        .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                        .foregroundColor(.green)
                        .frame(width: 300, height: 300)
                    // Look Right Guides
                    Circle()
                        .trim(from: 0.85, to: 1.0)
                        .rotation(.degrees(25))
                        .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                        .foregroundColor(.gray.opacity(0.3))
                        .frame(width: 300, height: 300)
                    Circle()
                        .trim(from: 0.85, to: 1.0)
                        .rotation(.degrees(25))
                        .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                        .foregroundColor(.gray.opacity(0.3))
                        .frame(width: 300, height: 300)
                    // Look Left Guides
                    Circle()
                        .trim(from: 0.85, to: 1.0)
                        .rotation(.degrees(210))
                        .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                        .foregroundColor(.gray.opacity(0.3))
                        .frame(width: 300, height: 300)
                    Circle()
                        .trim(from: 0.85, to: 1.0)
                        .rotation(.degrees(210))
                        .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                        .foregroundColor(.gray.opacity(0.3))
                        .frame(width: 300, height: 300)
                }
                VStack {
                    Text(viewModel.directive)
                        .multilineTextAlignment(.center)
                        .font(SmileID.theme.header1)
                        .foregroundColor(SmileID.theme.accent)
                        .padding(.top, 80)
                    Spacer()
                }
                .padding()
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

    // swiftlint:disable identifier_name
    @ViewBuilder func DebugView() -> some View {
        ZStack {
            FaceBoundingBoxView(model: viewModel)
            FaceLayoutGuideView(model: viewModel)
            VStack(spacing: 0) {
                Spacer()
                Text("xDelta: \(viewModel.boundingXDelta)")
                Text("yDelta: \(viewModel.boundingYDelta)")
                switch viewModel.isAcceptableBounds {
                case .unknown:
                    Text("Bounds - Unknown")
                case .detectedFaceTooSmall:
                    Text("Bounds - Face too small")
                case .detectedFaceTooLarge:
                    Text("Bounds - Face too large")
                case .detectedFaceOffCentre:
                    Text("Bounds - Face off Center")
                case .detectedFaceAppropriateSizeAndPosition:
                    Text("Bounds - Appropriate Size and Position")
                }
                Divider()
                Text("Yaw: \(viewModel.activeLiveness.yawAngle)")
                Text("Row: \(viewModel.activeLiveness.rollAngle)")
                Text("Pitch: \(viewModel.activeLiveness.pitchAngle)")
                Text("Quality: \(viewModel.faceQualityValue)")
                Text("Fail: \(viewModel.selfieQualityValue.failed) | Pass: \(viewModel.selfieQualityValue.passed)")
                    .font(.subheadline.weight(.medium))
                    .padding(5)
                    .background(Color.yellow)
                    .clipShape(.rect(cornerRadius: 5))
                    .padding(.bottom, 10)
                HStack {
                    switch viewModel.activeLiveness.faceDirection {
                    case .left:
                        Text("Looking Left")
                    case .right:
                        Text("Looking Right")
                    case .none:
                        Text("Looking Straight")
                    }
                    Spacer()
                    Button {
                        showImages = true
                    } label: {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(.yellow)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text("\(viewModel.livenessImages.count + (viewModel.selfieImage != nil ? 1 : 0))")
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            )
                    }
                }
            }
            .font(.footnote)
            .foregroundColor(.white)
            .padding(.bottom, 40)
            .padding(.horizontal)
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
