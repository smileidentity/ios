import SwiftUI
import Lottie

public struct SelfieCaptureScreenV2: View {
    @ObservedObject var viewModel = SelfieViewModelV2()
    let showAttribution: Bool
    
    @State private var playbackMode: LottiePlaybackMode = LottiePlaybackMode.paused

    public var body: some View {
        VStack(spacing: 40) {
            LottieView {
                try await DotLottieFile.named("si_anim_face", bundle: SmileIDResourcesHelper.bundle)
            }
            .playing(loopMode: .autoReverse)
            .frame(width: 80, height: 80)

            Text("Look up")
                .font(SmileID.theme.header2)
                .foregroundColor(.primary)
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.black, lineWidth: 20.0)
                    CameraView(cameraManager: viewModel.cameraManager)
                        .clipShape(.rect(cornerRadius: 25))
                        .onAppear {
                            viewModel.cameraManager.switchCamera(to: .front)
                        }
                CornerShapes()
                RoundedRectangle(cornerRadius: 25)
                    .foregroundColor(.white.opacity(0.8))
                    .cutout(Ellipse().scale(x: 0.8, y: 0.8))
            }
            .frame(width: 300, height: 400)

            if showAttribution {
                Image(uiImage: SmileIDResourcesHelper.SmileEmblem)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // swiftlint:disable identifier_name
    @ViewBuilder func CornerShapes() -> some View {
        VStack {
            HStack {
                // Top Left Corner
                CornerShape()
                    .stroke(SmileID.theme.success, style: StrokeStyle(lineWidth: 5))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(90))
                    .offset(x: -2.0, y: -2.0)
                Spacer()
                // Top Right Corner
                CornerShape()
                    .stroke(SmileID.theme.success, style: StrokeStyle(lineWidth: 5))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(180))
                    .offset(x: 2.0, y: -2.0)
            }
            Spacer()
            HStack {
                // Bottom Left Corner
                CornerShape()
                    .stroke(SmileID.theme.success, style: StrokeStyle(lineWidth: 5))
                    .frame(width: 40, height: 40)
                    .offset(x: -2.0, y: 2.0)
                Spacer()
                // Bottom Right Corner
                CornerShape()
                    .stroke(SmileID.theme.success, style: StrokeStyle(lineWidth: 5))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(270))
                    .offset(x: 2.0, y: 2.0)
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
