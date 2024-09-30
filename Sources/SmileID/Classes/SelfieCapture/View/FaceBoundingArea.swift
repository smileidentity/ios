import Lottie
import SwiftUI

struct FaceBoundingArea: View {
    var hasDetectedValidFace: Bool
    var showGuideAnimation: Bool
    var guideAnimation: CaptureGuideAnimation?

    @State private var playbackMode: LottiePlaybackMode = .paused

    var body: some View {
        ZStack {
            // Face Bounds Indicator
            Circle()
                .stroke(
                    hasDetectedValidFace ? .green : .red,
                    lineWidth: 10
                )
                .frame(width: 275, height: 275)

            if let guideAnimation = guideAnimation,
                showGuideAnimation {
                Circle()
                    .fill(.black.opacity(0.5))
                    .frame(width: 260, height: 260)
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
                    .clipShape(.circle)
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
