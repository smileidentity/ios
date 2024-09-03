import Lottie
import SwiftUI

public struct SelfieCaptureInstructionsView: View {
    let showAttribution: Bool
    let onInstructionsAcknowledged: () -> Void

    public var body: some View {
        VStack {
            LottieView {
              try await DotLottieFile.named("instructions_no_progress", bundle: SmileIDResourcesHelper.bundle)
            }
            .playing(loopMode: .loop)
            .frame(width: 235, height: 235)
            .padding(.top, 100)
            Spacer()
            Text(SmileIDResourcesHelper.localizedString(for: "Instructions.SelfieCapture"))
                .multilineTextAlignment(.center)
                .font(SmileID.theme.header4)
                .foregroundColor(SmileID.theme.tertiary)

            Spacer()

            VStack(spacing: 20) {
                SmileButton(
                    title: "Action.GetStarted",
                    clicked: onInstructionsAcknowledged
                )

                if showAttribution {
                    Image(uiImage: SmileIDResourcesHelper.SmileEmblem)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
}
