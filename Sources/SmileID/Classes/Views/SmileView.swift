import SwiftUI

struct SmileView: View {
    @EnvironmentObject var router: Router<NavigationDestination>
    private var viewFactory = ViewFactory()
    private let initialDestination: NavigationDestination
    init(initialDestination: NavigationDestination) {
        self.initialDestination = initialDestination
    }

    var body: some View {
        let _ = router.push(initialDestination)
        NavigationControllerHost(navTitle: "",
                                 navHidden: false,
                                 router: router,
                                 routeMap: ViewFactory().makeView(_:))
    }
}
