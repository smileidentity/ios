import SwiftUI
import Lottie

public struct SelfieCaptureScreenV2: View {
    @ObservedObject var viewModel: SelfieViewModelV2
    let showAttribution: Bool

    public var body: some View {
        VStack {
            ZStack {
                CameraView(cameraManager: viewModel.cameraManager)
                    .onAppear {
                        viewModel.cameraManager.switchCamera(to: .front)
                    }
                Rectangle()
                    .fill(.white)
                    .cutout(Ellipse().scale(x: 0.8, y: 0.8))
            }
            .frame(width: 300, height: 400)
            .padding(.top, 80)
            Text(SmileIDResourcesHelper.localizedString(for: viewModel.directive))
                .font(SmileID.theme.header2)
                .foregroundColor(.primary)
                .padding(.bottom)
                .padding(.horizontal)
            if viewModel.debugEnabled {
                DebugView()
            }
            Spacer()
            if showAttribution {
                Image(uiImage: SmileIDResourcesHelper.SmileEmblem)
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
        VStack(spacing: 0) {
            // Text("Progress: \(viewModel.captureProgress)")
            Text("Yaw: \(viewModel.yawValue)")
            Text("Row: \(viewModel.rollValue)")
            Text("Pitch: \(viewModel.pitchValue)")
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
        Spacer()
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

struct CornerShape: Shape {
    let width: CGFloat = 40
    let height: CGFloat = 40
    let cornerRadius: CGFloat = 25

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: height - cornerRadius))
        path.addArc(
            center: CGPoint(x: cornerRadius, y: height - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(90),
            clockwise: true
        )
        path.addLine(to: CGPoint(x: width, y: height))
        return path
    }
}
