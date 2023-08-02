import SwiftUI

class ViewFactory {

    class SelfiePlaceHolderDelegate: SmartSelfieResultDelegate {
        func didSucceed(selfieImage: Data, livenessImages: [Data], jobStatusResponse: JobStatusResponse?) {}
        func didError(error: Error) {}
    }
    
    class DocPlaceHolderDelegate: DocumentCaptureResultDelegate {
        func didSucceed(selfieImage: Data, livenessImages: [Data], jobStatusResponse: JobStatusResponse?) {}
        func didError(error: Error) {}
    }
    
    @ViewBuilder
    func makeView(_ destination: NavigationDestination) -> some View {
        switch destination {
        case .selfieInstructionScreen(let selfieCaptureViewModel,let delegate):
            SmartSelfieInstructionsView(viewModel: selfieCaptureViewModel, delegate: delegate ?? SelfiePlaceHolderDelegate())
        case .selfieCaptureScreen(let selfieCaptureViewModel,let delegate):
            SelfieCaptureView(viewModel: selfieCaptureViewModel, delegate: delegate ??  SelfiePlaceHolderDelegate())
        case .documentCaptureInstructionScreen(let documentCaptureViewModel,let delegate):
            DocumentCaptureInstructionsView(viewModel: documentCaptureViewModel, delegate: delegate ??  DocPlaceHolderDelegate())
        case .documentCaptureScreen(let documentCaptureViewModel,let delegate):
            DocumentCaptureInstructionsView(viewModel: documentCaptureViewModel, delegate: delegate ??  DocPlaceHolderDelegate())
        }
    }
}
