import Foundation
import SwiftUI

// MARK: - Native push container using UINavigationController

final class _CancelProxy: NSObject {
  var onTap: () -> Void
  init(onTap: @escaping () -> Void) {
    self.onTap = onTap
  }

  @objc func handleTap() {
    onTap()
  }
}

final class _NavBoxController: UINavigationController {
  var destinationStack: [NavigationDestination] = []
  var cancelProxy: _CancelProxy?
}

/// Bridges SwiftUI destinations into a real UINavigationController to get native push/pop animations on 13
struct PushNavigationContainer<Content: View>: UIViewControllerRepresentable {
  @ObservedObject var coordinator: VerificationCoordinator

  let titleFor: (NavigationDestination) -> String
  let makeView: (NavigationDestination) -> Content
  let onCancel: () -> Void

  let shouldHideBack: (NavigationDestination) -> Bool

  func makeUIViewController(context _: Context) -> _NavBoxController {
    let nav = _NavBoxController()
    nav.navigationBar.prefersLargeTitles = false

    // Root controller
    let rootDestination = coordinator.currentDestination
    let rootVC = UIHostingController(rootView: makeView(rootDestination))
    rootVC.title = titleFor(rootDestination)
    // Always hide the back button for a clean push flow
    rootVC.navigationItem.hidesBackButton = true
    nav.viewControllers = [rootVC]
    nav.destinationStack = [rootDestination]

    // Cancel button (except on .done)
    configureCancel(for: rootDestination, in: nav)
    return nav
  }

  func updateUIViewController(_ nav: _NavBoxController, context _: Context) {
    let desired = visibleStack()
    let current = nav.destinationStack

    guard desired != current else {
      if let top = nav.topViewController, let destination = desired.last {
        top.title = titleFor(destination)
        // Ensure back button remains hidden on updates
        top.navigationItem.hidesBackButton = true
        configureCancel(for: destination, in: nav)
      }
      return
    }

    // Determine push or pop
    if desired.count > current.count {
      // Push the new destinations
      for destination in desired.dropFirst(current.count) {
        let vc = UIHostingController(rootView: makeView(destination))
        vc.title = titleFor(destination)
        // Hide back button on newly pushed controllers
        vc.navigationItem.hidesBackButton = true
        nav.pushViewController(vc, animated: true)
      }
    } else if desired.count < current.count {
      // Pop to a previous controller
      let targetIndex = max(desired.count - 1, 0)
      if targetIndex < nav.viewControllers.count {
        let targetVC = nav.viewControllers[targetIndex]
        nav.popToViewController(targetVC, animated: true)
      } else {
        nav.setViewControllers(Array(nav.viewControllers.prefix(desired.count)), animated: false)
      }
    } else if desired.last != current.last {
      var vcs = nav.viewControllers
      if let destination = desired.last {
        let vc = UIHostingController(rootView: makeView(destination))
        vc.title = titleFor(destination)
        // Hide back button when replacing the top controller
        vc.navigationItem.hidesBackButton = true
        vcs[vcs.count - 1] = vc
        nav.setViewControllers(vcs, animated: false)
      }
    }

    nav.destinationStack = desired
    if let destination = desired.last { configureCancel(for: destination, in: nav) }
  }

  private func visibleStack() -> [NavigationDestination] {
    let fullRoute = coordinator.product.generateRoute()

    // Truncate up to currentDestination
    if let idx = fullRoute.firstIndex(of: coordinator.currentDestination) {
      return Array(fullRoute.prefix(idx + 1))
    }
    return [coordinator.currentDestination]
  }

  private func configureCancel(for destination: NavigationDestination, in nav: _NavBoxController) {
    guard let top = nav.topViewController else { return }
    if destination == .done {
      top.navigationItem.rightBarButtonItem = nil
    } else {
      let proxy = nav.cancelProxy ?? _CancelProxy(onTap: onCancel)
      nav.cancelProxy = proxy
      let item = UIBarButtonItem(
        title: "Cancel",
        style: .plain,
        target: proxy,
        action: #selector(_CancelProxy.handleTap)
      )
      top.navigationItem.rightBarButtonItem = item
    }
  }
}
