import SwiftUI

class ViewFactory {
    @ViewBuilder
    func makeView(_ destination: NavigationDestination) -> some View {
        switch destination {
        case let .selfieInstructionScreen(selfieCaptureViewModel, delegate):
            SmartSelfieInstructionsView(
                viewModel: selfieCaptureViewModel,
                delegate: delegate
            )
        case let .selfieCaptureScreen(selfieCaptureViewModel, delegate):
            SelfieCaptureView(
                viewModel: selfieCaptureViewModel,
                delegate: delegate
            )
        }
    }
}
