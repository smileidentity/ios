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
    rootVC.navigationItem.hidesBackButton = shouldHideBack(rootDestination)
    nav.viewControllers = [rootVC]
    nav.destinationStack = [rootDestination]

    // Cancel button (except on .done)
    configureCancel(for: rootDestination, in: nav)
    return nav
  }

  func updateUIViewController(_ nav: _NavBoxController, context _: Context) {
    // Desired stack is the prefix up to current index.
    let desired = visibleStack()
    let current = nav.destinationStack

    guard desired != current else {
      // Still update cancel/back state/title if needed
      if let top = nav.topViewController, let destination = desired.last {
        top.title = titleFor(destination)
        top.navigationItem.hidesBackButton = shouldHideBack(destination)
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
        vc.navigationItem.hidesBackButton = shouldHideBack(destination)
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
      // Same depth but different top (rare) → replace top without animation
      var vcs = nav.viewControllers
      if let destination = desired.last {
        let vc = UIHostingController(rootView: makeView(destination))
        vc.title = titleFor(destination)
        vc.navigationItem.hidesBackButton = shouldHideBack(destination)
        vcs[vcs.count - 1] = vc
        nav.setViewControllers(vcs, animated: false)
      }
    }

    nav.destinationStack = desired
    if let destination = desired.last { configureCancel(for: destination, in: nav) }
  }

  private func visibleStack() -> [NavigationDestination] {
    // Publicly expose the visible stack via currentDestination and internal route depth.
    // Since route is private, we approximate by replaying from start until currentDestination.
    // Coordinator advances one destination at a time, so we can build from product config deterministically.
    // Build the same route here:
    var destinations: [NavigationDestination] = []
    if coordinator.config.showInstructions { destinations.append(.instructions) }
    if coordinator.config.product.requiresDocInfo { destinations.append(.documentInfo) }
    if coordinator.config.product.requiresDocFront {
			destinations.append(.capture(.documentFront))
			destinations.append(.preview(.documentFront))
    }
    if coordinator.config.product.requiresDocBack {
			destinations.append(.capture(.documentBack))
			destinations.append(.preview(.documentBack))
    }
    if coordinator.config.product.requiresSelfie {
			destinations.append(.capture(.selfie))
			destinations.append(.preview(.selfie))
    }
		destinations.append(.processing)
		destinations.append(.done)
    // Truncate up to currentDestination
    if let idx = destinations.firstIndex(of: coordinator.currentDestination) {
      return Array(destinations.prefix(idx + 1))
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
