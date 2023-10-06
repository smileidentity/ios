import SwiftUI

class ViewFactory {
    class SelfiePlaceHolderDelegate: SmartSelfieResultDelegate {
        func didSucceed(
            selfieImage _: URL,
            livenessImages _: [URL],
            jobStatusResponse _: JobStatusResponse
        ) {}

        func didError(error _: Error) {}
    }

    class DocPlaceHolderDelegate: DocumentCaptureResultDelegate {
        func didSucceed(
            selfie: URL,
            documentFrontImage: URL,
            documentBackImage: URL?,
            jobStatusResponse: JobStatusResponse
        ) {}

        func didError(error _: Error) {}
    }

    @ViewBuilder
    func makeView(_ destination: NavigationDestination) -> some View {
        switch destination {
        case let .selfieInstructionScreen(selfieCaptureViewModel, delegate):
            SmartSelfieInstructionsView(
                viewModel: selfieCaptureViewModel,
                delegate: delegate ?? SelfiePlaceHolderDelegate()
            )
        case let .selfieCaptureScreen(selfieCaptureViewModel, delegate):
            SelfieCaptureView(
                viewModel: selfieCaptureViewModel,
                delegate: delegate ?? SelfiePlaceHolderDelegate()
            )
        case let .documentFrontCaptureInstructionScreen(documentCaptureViewModel):
            DocumentCaptureInstructionsView(
                viewModel: documentCaptureViewModel,
                side: .front
            )
        case let .documentCaptureScreen(documentCaptureViewModel):
            DocumentCaptureView(viewModel: documentCaptureViewModel)
        case .documentBackCaptureInstructionScreen(
            documentCaptureViewModel: let viewModel,
            let skipDestination
        ):
            DocumentCaptureInstructionsView(
                viewModel: viewModel,
                side: .back,
                skipDestination: skipDestination
            )
        case .documentCaptureProcessing:
            ModalPresenter(centered: true) {
                ProcessingView(
                    image: SmileIDResourcesHelper.Scan,
                    titleKey: "Document.Processing.Header",
                    calloutKey: "Document.Processing.Callout"
                )
            }
        case .documentCaptureComplete(viewModel: let viewModel):
            ModalPresenter {
                // SuccessView(
                //     titleKey: "Document.Complete.Header",
                //     bodyKey: "Document.Complete.Callout",
                //     clicked: viewModel.handleCompletion
                // )
            }
        case .documentCaptureError(viewModel: let viewModel):
            ModalPresenter {
                // ErrorView(viewModel: viewModel)
            }
        case .imagePicker(viewModel: let viewModel):
            Text("hello")
            // ImagePicker(delegate: viewModel)
        case .documentConfirmation(viewModel: let viewModel, image: let image):
            ModalPresenter {
                // ImageConfirmationView(
                //     viewModel: viewModel,
                //     header: "Document.Confirmation.Header",
                //     callout: "Document.Confirmation.Callout",
                //     confirmButtonTitle: "Document.Confirmation.Accept",
                //     declineButtonTitle: "Document.Confirmation.Decline",
                //     image: image
                // )
            }
        }
    }
}
