import Lottie
import SwiftUI

public struct LivenessCaptureInstructionsView: View {
    @Environment(\.modalMode) private var modalMode
    @State private var showSelfieCaptureView: Bool = false

    private let showAttribution: Bool
    private let viewModel: SelfieViewModelV2

    public init(showAttribution: Bool, viewModel: SelfieViewModelV2) {
        self.showAttribution = showAttribution
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack {
            HStack {
                Button {
                    self.modalMode.wrappedValue = false
                } label: {
                    Text(SmileIDResourcesHelper.localizedString(for: "Action.Cancel"))
                        .foregroundColor(SmileID.theme.accent)
                }
                Spacer()
            }

            ZStack {
                LottieView {
                    try await DotLottieFile.named("instructions_no_progress", bundle: SmileIDResourcesHelper.bundle)
                }
                .playing(loopMode: .loop)
                .frame(width: 235, height: 235)
            }
            .padding(.top, 100)
            Spacer()
            Text(SmileIDResourcesHelper.localizedString(for: "Instructions.SelfieCapture"))
                .multilineTextAlignment(.center)
                .font(SmileID.theme.header4)
                .foregroundColor(SmileID.theme.tertiary)

            Spacer()

            VStack(spacing: 20) {
                NavigationLink(
                    destination: SelfieCaptureScreenV2(
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
