import Lottie
import SwiftUI

public struct LivenessCaptureInstructionsView: View {
    @State private var showSelfieCaptureView: Bool = false

    private let showAttribution: Bool
    private let viewModel: EnhancedSmartSelfieViewModel

    public init(showAttribution: Bool, viewModel: EnhancedSmartSelfieViewModel) {
        self.showAttribution = showAttribution
        self.viewModel = viewModel
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
                NavigationLink(
                    destination: EnhancedSelfieCaptureScreen(
                        viewModel: viewModel,
                        showAttribution: showAttribution
                    ),
                    isActive: $showSelfieCaptureView
                ) { EmptyView() }

                SmileButton(
                    title: "Action.GetStarted",
                    clicked: {
                        self.showSelfieCaptureView = true
                    }
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
