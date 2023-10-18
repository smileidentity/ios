import SwiftUI

public struct SmartSelfieInstructionsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var router: Router<NavigationDestination>
    private var selfieCaptureDelegate: SmartSelfieResultDelegate?
    @State private var goesToDetail: Bool = false
    @State var viewModel: SelfieCaptureViewModel

    init(viewModel: SelfieCaptureViewModel, delegate: SmartSelfieResultDelegate?) {
        selfieCaptureDelegate = delegate
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        if let processingState = viewModel.processingState, processingState == .endFlow {
            let _ = DispatchQueue.main.async {
                router.dismiss()
            }
        }
        VStack {
            CaptureInstructionView<SelfieCaptureView>(
                image: SmileIDResourcesHelper.InstructionsHeaderIcon,
                title: SmileIDResourcesHelper.localizedString(for: "Instructions.Header"),
                callOut: SmileIDResourcesHelper.localizedString(for: "Instructions.Callout"),
                buttonTitle: "Instructions.Action",
                instructions: [
                    CaptureInstruction(
                        title: SmileIDResourcesHelper.localizedString(
                            for: "Instructions.GoodLight"
                        ),
                        instruction: SmileIDResourcesHelper.localizedString(
                            for: "Instructions.GoodLightBody"
                        ),
                        image: Constants.ImageName.light
                    ),
                    CaptureInstruction(
                        title: SmileIDResourcesHelper.localizedString(
                            for: "Instructions.ClearImage"
                        ),
                        instruction: SmileIDResourcesHelper.localizedString(
                            for: "Instructions.ClearImageBody"
                        ),
                        image: Constants.ImageName.clearImage
                    ),
                    CaptureInstruction(
                        title: SmileIDResourcesHelper.localizedString(
                            for: "Instructions.RemoveObstructions"
                        ),
                        instruction: SmileIDResourcesHelper.localizedString(
                            for: "Instructions.RemoveObstructionsBody"
                        ),
                        image: Constants.ImageName.face
                    )
                ],
                captureType: .selfie,
                destination: .selfieCaptureScreen(
                    selfieCaptureViewModel: viewModel,
                    delegate: selfieCaptureDelegate
                ),
                showAttribution: viewModel.showAttribution
            )
                .padding(.top, 50)
        }
    }
}
