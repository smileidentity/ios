import Lottie
import SwiftUI

struct FaceBoundingArea: View {
    @State private var playbackMode: LottiePlaybackMode = .paused

    // Constants
    private let lookRightAnimationRange: ClosedRange<CGFloat> = 0...0.4
    private let lookLeftAnimationRange: ClosedRange<CGFloat> = 0.4...0.64
    private let lookUpAnimationRange: ClosedRange<CGFloat> = 0.64...1.0

    var body: some View {
        ZStack {
            // Face Bounds Indicator
            Circle()
                .stroke(.red, lineWidth: 10)
                .frame(width: 275, height: 275)
            Circle()
                .fill(.black.opacity(0.5))
                .frame(width: 260, height: 260)
                .overlay(
                    LottieView {
                        try await DotLottieFile.named("liveness_guides", bundle: SmileIDResourcesHelper.bundle)
                    }
                    .playbackMode(playbackMode)
                    .frame(width: 224, height: 224)
                )
        }
        .onAppear {
            playbackMode = getPlaybackMode()
        }
    }

    private func getPlaybackMode() -> LottiePlaybackMode {
        return .playing(
            .fromProgress(
                lookUpAnimationRange.lowerBound,
                toProgress: lookUpAnimationRange.upperBound,
                loopMode: .autoReverse
            )
        )
    }
}
