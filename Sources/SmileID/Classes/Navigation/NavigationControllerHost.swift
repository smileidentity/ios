import UIKit
import SwiftUI

public struct NavigationControllerHost<R: Equatable, Screen: View>: UIViewControllerRepresentable {
    public let navTitle: String
    public let navHidden: Bool
    public let router: Router<R>

    @ViewBuilder
    public var routeMap: (R) -> Screen

    public init(
        navTitle: String,
        navHidden: Bool,
        router: Router<R>,
        routeMap: @escaping (R) -> Screen
    ) {
        self.navTitle = navTitle
        self.navHidden = navHidden
        self.router = router
        self.routeMap = routeMap
    }

    public func makeUIViewController(context: Context) -> PoppableNavigationController {
        let nav = PoppableNavigationController()

        nav.popHandler = { router.onUIKitPop() }
        nav.navStackHandler = { router.routes.count }
        nav.dismissHandler = { router.dismiss() }

        for path in router.routes {
            nav.pushViewController(
                UIHostingController(rootView: routeMap(path)), animated: true
            )
        }

        router.presentHandler = { route in
            nav.present(UIHostingController(rootView: routeMap(route)), animated: true)
        }

        router.pushHandler = { route, animated in
            nav.pushViewController(
                UIHostingController(rootView: routeMap(route)), animated: animated
            )
        }

        router.dismissHandler = { nav.dismiss(animated: true) }

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

    public func updateUIViewController(_ navigation: PoppableNavigationController, context: Context) {
        navigation.topViewController?.navigationItem.title = navTitle
        navigation.navigationBar.isHidden = navHidden
        navigation.navigationBar.backIndicatorImage = SmileIDResourcesHelper.ArrowLeft
        navigation.navigationBar.backIndicatorTransitionMaskImage = SmileIDResourcesHelper.ArrowLeft
        navigation.navigationBar.barTintColor = SmileID.theme.backgroundMain.uiColor()
        let barButton = UIBarButtonItem(
            image: SmileIDResourcesHelper.Close,
            style: .plain,
            target: navigation,
            action: #selector(navigation.dismissNav)
        )
        navigation.topViewController?.navigationItem.leftBarButtonItem = barButton
    }

    public typealias UIViewControllerType = PoppableNavigationController
}

public class PoppableNavigationController: UINavigationController, UINavigationControllerDelegate {
    var popHandler: (() -> Void)?
    var dismissHandler: (() -> Void)?
    var navStackHandler: (() -> Int)?

    var popGestureBeganController: UIViewController?

    public override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        interactivePopGestureRecognizer?.isEnabled = false
    }

    public func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {

        if let stackSizeProvider = navStackHandler, stackSizeProvider() >
            navigationController.viewControllers.count {
            popHandler?()
        }
    }

    @objc func dismissNav() {
        dismissHandler?()
    }
}
