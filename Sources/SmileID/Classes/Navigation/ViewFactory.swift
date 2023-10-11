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
        }
    }
}
