import SwiftUI

class NavigationViewModel: ObservableObject {
    @Published
    var navigationDirection: NavigationDirection?

    func showDocCaptureScreen(viewModel: DocumentCaptureViewModel,
                              delegate: DocumentCaptureResultDelegate) {
        navigationDirection = .forward(destination:
            .documentFrontCaptureInstructionScreen(documentCaptureViewModel:
                viewModel, delegate:
                delegate), style: .present)
    }

    func navigate(destination: NavigationDestination, style: NavigationStyle) {
        navigationDirection = .forward(destination: destination, style: style)
    }

    func dismiss() {
        navigationDirection = .back
    }
}
