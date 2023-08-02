import SwiftUI

struct SmileUIView: View {
    @EnvironmentObject var viewModel: NavigationViewModel
    private var viewFactory = ViewFactory()
    private let initialDestination: NavigationDestination
    init(initialDestination: NavigationDestination) {
        self.initialDestination = initialDestination
    }

    var body: some View {
        NavigationView {
            viewFactory.makeView(self.initialDestination)
                .handleNavigation($viewModel.navigationDirection)
        }
    }
}
