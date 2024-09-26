import Lottie
import SwiftUI

struct FaceBoundingArea: View {
    let viewModel: SelfieViewModelV2

    init(viewModel: SelfieViewModelV2) {
        self.viewModel = viewModel
    }

    @State private var playbackMode: LottiePlaybackMode = .paused

    var body: some View {
        ZStack {
            // Face Bounds Indicator
            Circle()
                .stroke(
                    viewModel.isAcceptableBounds == .detectedFaceAppropriateSizeAndPosition ? .green : .red,
                    lineWidth: 10
                )
                .frame(width: 275, height: 275)
            if let guideAnimation = viewModel.guideAnimation,
                viewModel.showGuideAnimation {
                Circle()
                    .fill(.black.opacity(0.5))
                    .frame(width: 260, height: 260)
                    .overlay(
                        LottieView {
                            try await DotLottieFile.named(guideAnimation.fileName, bundle: SmileIDResourcesHelper.bundle)
                        }
                        .playbackMode(playbackMode)
                        .frame(width: 224, height: 224)
                    )
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
