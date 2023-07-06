import SwiftUI

public struct SmartSelfieInstructionsView: View {
    @Environment(\.presentationMode) var presentationMode
    private weak var selfieCaptureDelegate: SmartSelfieResultDelegate?
    @State private var goesToDetail: Bool = false
    @State var viewModel: SelfieCaptureViewModel

    init(viewModel: SelfieCaptureViewModel, delegate: SmartSelfieResultDelegate) {
        self.selfieCaptureDelegate = delegate
        _viewModel = State(initialValue: viewModel)

    }

    // Only exists for preview so not accessible out of the file
//    fileprivate init() {
//    }

    public var body: some View {
        if let processingState = viewModel.processingState, processingState == .endFlow {
            let _ = DispatchQueue.main.async {
                presentationMode.wrappedValue.dismiss()
            }
        }
        CaptureInstructionView<SelfieCaptureView>(
            image: SmileIDResourcesHelper.InstructionsHeaderIcon,
            title: SmileIDResourcesHelper.localizedString(for: "Instructions.Header"),
            callOut: SmileIDResourcesHelper.localizedString(for: "Instructions.Callout"),
            instructions: [
                CaptureInstruction(title: SmileIDResourcesHelper.localizedString(for: "Instructions.GoodLight"),
                                   instruction: SmileIDResourcesHelper.localizedString(for: "Instructions.GoodLightBody"),
                                   image: Constants.ImageName.light),
                CaptureInstruction(title: SmileIDResourcesHelper.localizedString(for: "Instructions.ClearImage"),
                                   instruction: SmileIDResourcesHelper.localizedString(for: "Instructions.ClearImageBody"),
                                   image: Constants.ImageName.clearImage),
                CaptureInstruction(title: SmileIDResourcesHelper.localizedString(for: "Instructions.RemoveObstructions"),
                                   instruction: SmileIDResourcesHelper.localizedString(for: "Instructions.RemoveObstructionsBody"),
                                   image: Constants.ImageName.face),
            ],
            detailView: SelfieCaptureView(
                viewModel: viewModel,
                delegate: selfieCaptureDelegate ??
                    DummyDelegate()
            )
        )
    }
}

//struct SmartSelfieInstructionsView_Previews: PreviewProvider {
//    static var previews: some View {
//        SmartSelfieInstructionsView(viewModel: SelfieCaptureViewModel(userId: UUID().uuidString,
//                                                                      jobId: UUID().uuidString,
//                                                                      isEnroll: false,
//                                                                      showAttribution: true), delegate: <#SmartSelfieResultDelegate#>)
//        .environment(\.locale, Locale(identifier: "en"))
//
//    }
//}
