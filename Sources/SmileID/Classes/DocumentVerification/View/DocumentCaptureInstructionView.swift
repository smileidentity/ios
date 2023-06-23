import SwiftUI
///Instructionf for document capture
public struct DocumentCaptureInstructionsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var viewModel : DocumentCaptureViewModel
    private weak var documentCaptureDelegate: DocumentCaptureResultDelegate?
    
    init(viewModel: DocumentCaptureViewModel, delegate: DocumentCaptureResultDelegate) {
        self.viewModel = viewModel
        self.documentCaptureDelegate = delegate
    }
    
    fileprivate init(viewModel: DocumentCaptureViewModel) {
        self.viewModel = viewModel
    }
    public var body: some View {
        ///we're using the selfie capture view for now to show it's working
        CaptureInstructionView<SelfieCaptureView>(
            image: SmileIDResourcesHelper.InstructionsHeaderdDocumentIcon,
            title: SmileIDResourcesHelper.localizedString(for: "Instructions.Document.Header"),
            callOut: SmileIDResourcesHelper.localizedString(for: "Instructions.Document.Callout"),
            instructions: [
                CaptureInstruction(title: SmileIDResourcesHelper.localizedString(for:"Instructions.GoodLight"),
                                   instruction: SmileIDResourcesHelper.localizedString(for:"Instructions.GoodLightBody"),
                                   image: Constants.ImageName.light),
                CaptureInstruction(title: SmileIDResourcesHelper.localizedString(for:"Instructions.ClearImage"),
                                   instruction: SmileIDResourcesHelper.localizedString(for:"Instructions.ClearImageBody"),
                                   image: Constants.ImageName.clearImage)],
            detailView:SelfieCaptureView(
                viewModel: SelfieCaptureViewModel(userId: "", jobId: "", isEnroll: false),
                delegate: DummyDelegate()))
    }
}

struct DocumentCaptureInstructionsView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentCaptureInstructionsView(viewModel: DocumentCaptureViewModel())
            .environment(\.locale, Locale(identifier: "en"))
        
    }
}
