import SwiftUI

public struct SmartSelfieInstructionsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var viewModel : SelfieCaptureViewModel
    private weak var selfieCaptureDelegate: SmartSelfieResultDelegate?
    @State private var goesToDetail: Bool = false
    
    init(viewModel: SelfieCaptureViewModel, delegate: SmartSelfieResultDelegate) {
        self.viewModel = viewModel
        self.selfieCaptureDelegate = delegate
    }
    
    // Only exists for preview so not accessible out of the file
    fileprivate init(viewModel: SelfieCaptureViewModel) {
        self.viewModel = viewModel
    }
    public var body: some View {
        CaptureInstructionView<SelfieCaptureView>(
            image: SmileIDResourcesHelper.InstructionsHeaderIcon,
            title: SmileIDResourcesHelper.localizedString(for: "Instructions.Header"),
            callOut: SmileIDResourcesHelper.localizedString(for: "Instructions.Callout"),
            instructions: [
                CaptureInstruction(title: SmileIDResourcesHelper.localizedString(for:"Instructions.GoodLight"),
                                   instruction: SmileIDResourcesHelper.localizedString(for:"Instructions.GoodLightBody"),
                                   image: Constants.ImageName.light),
                CaptureInstruction(title: SmileIDResourcesHelper.localizedString(for:"Instructions.ClearImage"),
                                   instruction: SmileIDResourcesHelper.localizedString(for:"Instructions.ClearImageBody"),
                                   image: Constants.ImageName.clearImage),
                CaptureInstruction(title: SmileIDResourcesHelper.localizedString(for:"Instructions.RemoveObstructions"),
                                   instruction: SmileIDResourcesHelper.localizedString(for:"Instructions.RemoveObstructionsBody"),
                                   image: Constants.ImageName.face)],
            detailView: SelfieCaptureView(
                viewModel: viewModel,
                delegate: selfieCaptureDelegate ??
                DummyDelegate()))
        
    }
}

struct SmartSelfieInstructionsView_Previews: PreviewProvider {
    static var previews: some View {
        SmartSelfieInstructionsView(viewModel: SelfieCaptureViewModel(userId: UUID().uuidString,
                                                                      jobId: UUID().uuidString,
                                                                      isEnroll: false,
                                                                      showAttribution: true))
        .environment(\.locale, Locale(identifier: "en"))
        
    }
}
