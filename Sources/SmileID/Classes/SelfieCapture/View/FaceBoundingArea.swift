import Lottie
import SwiftUI

struct FaceBoundingArea: View {
    var faceInBounds: Bool
    var selfieCaptured: Bool
    var showGuideAnimation: Bool
    var guideAnimation: CaptureGuideAnimation?

    @State private var playbackMode: LottiePlaybackMode = .paused

    var body: some View {
        ZStack {
            // Face Bounds Indicator
            FaceShape()
                .stroke(
                    faceInBounds ? selfieCaptured ? .clear : SmileID.theme.success : SmileID.theme.error,
                    style: StrokeStyle(lineWidth: 10)
                )
                .frame(width: 270, height: 370)
                .opacity(0)

            if let guideAnimation = guideAnimation,
                showGuideAnimation {
                FaceShape()
                    .fill(.black.opacity(0.5))
                    .frame(width: 250, height: 350)
                    .overlay(
                        LottieView {
                            try await DotLottieFile
                                .named(
                                    guideAnimation.fileName,
                                    bundle: SmileIDResourcesHelper.bundle
                                )
                        }
                        .playbackMode(playbackMode)
                        .frame(width: 224, height: 224)
                    )
                    .clipShape(FaceShape())
                    .onAppear {
                        playbackMode = getPlaybackMode(guideAnimation)
                    }
            }
        }
    }

    private func getPlaybackMode(_ animation: CaptureGuideAnimation) -> LottiePlaybackMode {
        return .playing(
            .fromProgress(
                animation.animationProgressRange.lowerBound,
                toProgress: animation.animationProgressRange.upperBound,
                loopMode: .autoReverse
            )
        )
    }
}
