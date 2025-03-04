import Lottie
import SwiftUI

public struct LivenessCaptureInstructionsView: View {
    private let showAttribution: Bool
    private var didTapGetStarted: () -> Void

    public init(
        showAttribution: Bool,
        didTapGetStarted: @escaping () -> Void
    ) {
        self.showAttribution = showAttribution
        self.didTapGetStarted = didTapGetStarted
    }

    public var body: some View {
        VStack {
            ZStack {
                LottieView {
                    try await DotLottieFile
                        .named(
                            "instruction_screen_with_side_bar",
                            bundle: SmileIDResourcesHelper.bundle
                        )
                }
                .playing(loopMode: .loop)
                .frame(width: 235, height: 235)
            }
            .padding(.top, 80)
            Spacer()
            Text(SmileIDResourcesHelper.localizedString(for: "Instructions.SelfieCapture"))
                .multilineTextAlignment(.center)
                .font(SmileID.theme.header4)
                .lineSpacing(4)
                .foregroundColor(SmileID.theme.tertiary)

            Spacer()

            VStack(spacing: 20) {
                SmileButton(
                    title: "Action.GetStarted",
                    clicked: didTapGetStarted
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
