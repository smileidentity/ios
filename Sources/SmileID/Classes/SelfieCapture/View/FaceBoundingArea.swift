import Lottie
import SwiftUI

struct FaceBoundingArea: View {
    var body: some View {
        ZStack {
            // Face Bounds Indicator
            Circle()
                .stroke(.red, lineWidth: 10)
                .frame(width: 275, height: 275)
                .hidden()
            Circle()
                .fill(.black.opacity(0.5))
                .frame(width: 260, height: 260)
                .overlay(
                    LottieView {
                        try await DotLottieFile.named("liveness_guides", bundle: SmileIDResourcesHelper.bundle)
                    }
                    .playing(loopMode: .loop)
                    .frame(width: 224, height: 224)
                )
        }
    }
}
