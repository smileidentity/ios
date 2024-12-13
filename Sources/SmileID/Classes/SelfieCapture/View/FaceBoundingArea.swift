import Lottie
import SwiftUI

struct FaceBoundingArea: View {
    var faceInBounds: Bool
    var selfieCaptured: Bool
    var showGuideAnimation: Bool
    var guideAnimation: CaptureGuideAnimation?

    private let faceShape = FaceShape()
    @State private var playbackMode: LottiePlaybackMode = .paused

    var body: some View {
        ZStack {
            // Face Bounds Indicator
            faceShape
                .stroke(
                    faceInBounds ? selfieCaptured ? .clear : SmileID.theme.success : SmileID.theme.error,
                    style: StrokeStyle(lineWidth: 8)
                )
                .frame(width: 260, height: 360)

            if let guideAnimation = guideAnimation,
                showGuideAnimation {
                LottieView {
                    try await DotLottieFile
                        .named(
                            guideAnimation.fileName,
                            bundle: SmileIDResourcesHelper.bundle
                        )
                }
                .playbackMode(playbackMode)
                .frame(width: 224, height: 224)
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
