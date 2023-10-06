import SwiftUI

public struct DocumentCaptureInstructionsView: View {
    enum Side {
        case front
        case back
    }

    @EnvironmentObject var router: Router<NavigationDestination>
    @ObservedObject private var viewModel: DocumentCaptureViewModel
    private var side: Side
    private var skipDestination: NavigationDestination?

    init(
        viewModel: DocumentCaptureViewModel,
        side: Side,
        skipDestination: NavigationDestination? = nil
    ) {
        self.viewModel = viewModel
        self.side = side
        self.skipDestination = skipDestination
    }

    fileprivate init(viewModel: DocumentCaptureViewModel) {
        self.viewModel = viewModel
        side = .back
    }

    public var body: some View {
        // if let processingState = viewModel.processingState, processingState == .endFlow {
        //     let _ = DispatchQueue.main.async {
        //         router.dismiss()
        //     }
        // }

        VStack {
            switch side {
            case .front:
                createFrontInstructions()
                    .onAppear {
                        // viewModel.router = router
                    }
            case .back:
                createBackInstructions()
            }
        }
            .overlay(NavigationBar {
                if side == .back {
                    router.pop()
                } else {
                    router.dismiss()
                }
            })
    }

    func createBackInstructions() -> some View {
        Text("hello")
        // CaptureInstructionView<DocumentCaptureView>(
        //     image: UIImage(),
        //     title: SmileIDResourcesHelper.localizedString(for: "Instructions.Document.Back.Header"),
        //     callOut: SmileIDResourcesHelper.localizedString(
        //         for: "Instructions.Document.Back.Callout"
        //     ),
        //     buttonTitle: "Action.TakePhoto",
        //     instructions: [
        //         CaptureInstruction(
        //             title: SmileIDResourcesHelper.localizedString(for: "Instructions.GoodLight"),
        //             instruction: SmileIDResourcesHelper.localizedString(
        //                 for: "Instructions.GoodLightBody"
        //             ),
        //             image: Constants.ImageName.light
        //         ),
        //         CaptureInstruction(
        //             title: SmileIDResourcesHelper.localizedString(for: "Instructions.ClearImage"),
        //             instruction: SmileIDResourcesHelper.localizedString(
        //                 for: "Instructions.ClearImageBody"
        //             ),
        //             image: Constants.ImageName.clearImage)
        //     ],
        //     captureType: .document(.back),
        //     destination: .documentCaptureScreen(
        //         documentCaptureViewModel: viewModel
        //     ),
        //     secondaryDestination: .imagePicker(viewModel: viewModel),
        //     skipDestination: skipDestination,
        //     showAttribution: viewModel.showAttribution,
        //     allowGalleryUpload: viewModel.allowGalleryUpload)
        //     .padding(.top, 50)
    }

    func createFrontInstructions() -> some View {
        CaptureInstructionView<DocumentCaptureView>(
            image: SmileIDResourcesHelper.InstructionsHeaderDocumentIcon,
            title: SmileIDResourcesHelper.localizedString(for:
                                                          "Instructions.Document.Front.Header"),
            callOut: SmileIDResourcesHelper.localizedString(for:
                                                            "Instructions.Document.Front.Callout"),
            buttonTitle: "Action.TakePhoto",
            instructions: [
                CaptureInstruction(
                    title: SmileIDResourcesHelper.localizedString(for: "Instructions.GoodLight"),
                    instruction: SmileIDResourcesHelper.localizedString(
                        for: "Instructions.GoodLightBody"
                    ),
                    image: Constants.ImageName.light
                ),
                CaptureInstruction(
                    title: SmileIDResourcesHelper.localizedString(for: "Instructions.ClearImage"),
                    instruction: SmileIDResourcesHelper.localizedString(
                        for: "Instructions.ClearImageBody"
                    ),
                    image: Constants.ImageName.clearImage
                )
            ],
            captureType: .document(.front),
            destination: .documentCaptureScreen(
                documentCaptureViewModel: viewModel
            ),
            secondaryDestination: .imagePicker(viewModel: viewModel),
            showAttribution: true,
            allowGalleryUpload: true
        ).padding(.top, 50)
    }
}

// struct DocumentCaptureInstructionsView_Previews: PreviewProvider {
//     static var previews: some View {
//         DocumentCaptureInstructionsView(
//             viewModel: DocumentCaptureViewModel(
//                 userId: "",
//                 jobId: "",
//                 countryCode: "",
//                 documentType: "",
//                 captureBothSides: true,
//                 showAttribution: true,
//                 allowGalleryUpload: true,
//                 delegate: DocPlaceHolderDelegate()
//             )
//         ).environment(\.locale, Locale(identifier: "en"))
//     }
//
//     private class DocPlaceHolderDelegate: DocumentCaptureResultDelegate {
//         func didSucceed(
//             selfie: URL,
//             documentFrontImage: URL,
//             documentBackImage: URL?,
//             jobStatusResponse: JobStatusResponse
//         ) {}
//
//         func didError(error _: Error) {}
//     }
// }
