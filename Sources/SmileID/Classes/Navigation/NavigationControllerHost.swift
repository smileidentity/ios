import UIKit
import SwiftUI

struct NavigationControllerHost<R: Equatable, Screen: View>: UIViewControllerRepresentable {

    let navTitle: String
    let navHidden: Bool

    let router: Router<R>

    @ViewBuilder
    var routeMap: (R) -> Screen

    func makeUIViewController(context: Context) -> UINavigationController {
        let nav = PoppableNavigationController()

        nav.popHandler = {
            router.onUIKitPop()
        }
        nav.navStackHandler = {
            router.routes.count
        }

        for path in router.routes {
            nav.pushViewController(
                UIHostingController(rootView: routeMap(path)), animated: true
            )
        }

        router.pushHandler = { route in
            nav.pushViewController(
                UIHostingController(rootView: routeMap(route)), animated: true
            )
        }

        router.popHandler = { numToPop, animated in
            if numToPop == nav.viewControllers.count {
                nav.viewControllers = []
            } else {
                let popTo = nav.viewControllers[nav.viewControllers.count - numToPop - 1]
                nav.popToViewController(popTo, animated: animated)
            }
        }

        return nav
    }

    func updateUIViewController(_ navigation: UINavigationController, context: Context) {
        navigation.topViewController?.navigationItem.title = navTitle
        navigation.navigationBar.isHidden = navHidden
    }

    typealias UIViewControllerType = UINavigationController
}

class PoppableNavigationController: UINavigationController, UINavigationControllerDelegate
{
    var popHandler: (() -> Void)?
    var navStackHandler: (() -> Int)?

    var popGestureBeganController: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
    }

    func navigationController(_ navigationController: UINavigationController,
                              didShow viewController: UIViewController,
                              animated: Bool) {

        if let stackSizeProvider = navStackHandler, stackSizeProvider() > navigationController.viewControllers.count {
            self.popHandler?()
        }
    }
}

