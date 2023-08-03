import SwiftUI

class ViewFactory {
    class SelfiePlaceHolderDelegate: SmartSelfieResultDelegate {
        func didSucceed(selfieImage _: Data, livenessImages _: [Data], jobStatusResponse _: JobStatusResponse?) {}
        func didError(error _: Error) {}
    }

    class DocPlaceHolderDelegate: DocumentCaptureResultDelegate {
        func didSucceed(selfieImage _: Data, livenessImages _: [Data], jobStatusResponse _: JobStatusResponse?) {}
        func didError(error _: Error) {}
    }

    @ViewBuilder
    func makeView(_ destination: NavigationDestination) -> some View {
        switch destination {
        case let .selfieInstructionScreen(selfieCaptureViewModel, delegate):
            SmartSelfieInstructionsView(viewModel:
                                            selfieCaptureViewModel,
                                        delegate: delegate ?? SelfiePlaceHolderDelegate())
        case let .selfieCaptureScreen(selfieCaptureViewModel, delegate):
            SelfieCaptureView(viewModel:
                                selfieCaptureViewModel, delegate:
                                delegate ?? SelfiePlaceHolderDelegate())
        case let .documentCaptureInstructionScreen(documentCaptureViewModel, delegate):
            DocumentCaptureInstructionsView(viewModel: documentCaptureViewModel,
                                            delegate: delegate ?? DocPlaceHolderDelegate())
        case let .documentCaptureScreen(documentCaptureViewModel, _):
            DocumentCaptureView(viewModel: documentCaptureViewModel)
        }
    }
}
