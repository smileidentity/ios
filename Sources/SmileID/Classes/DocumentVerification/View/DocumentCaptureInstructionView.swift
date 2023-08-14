import SwiftUI
/// Instructionf for document capture
public struct DocumentCaptureInstructionsView: View {
    enum Position {
        case front
        case back
    }

    @EnvironmentObject var navigationViewModel: NavigationViewModel
    @ObservedObject private var viewModel: DocumentCaptureViewModel
    private var position: Position
    private weak var documentCaptureDelegate: DocumentCaptureResultDelegate?

    init(viewModel: DocumentCaptureViewModel, postion: Position, delegate: DocumentCaptureResultDelegate) {
        self.viewModel = viewModel
        self.position = postion
        documentCaptureDelegate = delegate
    }

    fileprivate init(viewModel: DocumentCaptureViewModel) {
        self.viewModel = viewModel
        self.position = .back
    }

    public var body: some View {
        switch position {
        case .front:
            createFrontInstructions()
        case .back:
            createBackInstuctions()
        }
    }

    func createBackInstuctions() -> CaptureInstructionView<DocumentCaptureView> {
        CaptureInstructionView<DocumentCaptureView>(image: UIImage(),
                                                    title: SmileIDResourcesHelper.localizedString(for: "Instructions.Document.Back.Header"),
                                                    callOut: SmileIDResourcesHelper.localizedString(for: "Instructions.Document.Back.Callout"),
                                                    instructions: [],
                                                    captureType: .document,
                                                    destination: .documentCaptureScreen(documentCaptureViewModel: viewModel,
                                                                                        delegate: documentCaptureDelegate),
                                                    showAttribution: true)

    }

    func createFrontInstructions() -> CaptureInstructionView<DocumentCaptureView> {
        CaptureInstructionView<DocumentCaptureView>(
            image: SmileIDResourcesHelper.InstructionsHeaderdDocumentIcon,
            title: SmileIDResourcesHelper.localizedString(for: "Instructions.Document.Header"),
            callOut: SmileIDResourcesHelper.localizedString(for: "Instructions.Document.Callout"),
            instructions: [
                CaptureInstruction(title:
                                    SmileIDResourcesHelper.localizedString(for: "Instructions.GoodLight"),
                                   instruction:
                                    SmileIDResourcesHelper.localizedString(for: "Instructions.GoodLightBody"),
                                   image: Constants.ImageName.light),
                CaptureInstruction(title:
                                    SmileIDResourcesHelper.localizedString(for: "Instructions.ClearImage"),
                                   instruction:
                                    SmileIDResourcesHelper.localizedString(for: "Instructions.ClearImageBody"),
                                   image: Constants.ImageName.clearImage),
            ], captureType: .document,
            destination: .documentCaptureScreen(documentCaptureViewModel: viewModel, delegate: documentCaptureDelegate),
            // TO-DO: Get value from viewModel after document capture feature is complete
            showAttribution: true
        )
    }
}

struct DocumentCaptureInstructionsView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentCaptureInstructionsView(viewModel: DocumentCaptureViewModel(userId: "",
                                                                            jobId: "",
                                                                            document: Document(countryCode: "",
                                                                                               documentType: "",
                                                                                               aspectRatio: 0.2),
                                                                            captureBothSides: true))
            .environment(\.locale, Locale(identifier: "en"))
    }
}
