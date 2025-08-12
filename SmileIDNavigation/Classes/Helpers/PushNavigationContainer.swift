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
	var stepStack: [Step] = []
	var cancelProxy: _CancelProxy?
}

/// Bridges SwiftUI steps into a real UINavigationController to get native push/pop animations on 13
struct PushNavigationContainer<Content: View>: UIViewControllerRepresentable {
	@ObservedObject var coordinator: VerificationCoordinator

	let titleFor: (Step) -> String
	let makeView: (Step) -> Content
	let onCancel: () -> Void

	let shouldHideBack: (Step) -> Bool

	func makeUIViewController(context: Context) -> _NavBoxController {
		let nav = _NavBoxController()
		nav.navigationBar.prefersLargeTitles = false

		// Root controller
		let rootStep = coordinator.currentStep
		let rootVC = UIHostingController(rootView: makeView(rootStep))
		rootVC.title = titleFor(rootStep)
		rootVC.navigationItem.hidesBackButton = shouldHideBack(rootStep)
		nav.viewControllers = [rootVC]
		nav.stepStack = [rootStep]

		// Cancel button (except on .done)
		configureCancel(for: rootStep, in: nav)
		return nav
	}

	func updateUIViewController(_ nav: _NavBoxController, context: Context) {
		// Desired stack is the prefix up to current index.
		let desired = visibleStack()
		let current = nav.stepStack

		guard desired != current else {
			// Still update cancel/back state/title if needed
			if let top = nav.topViewController, let step = desired.last {
				top.title = titleFor(step)
				top.navigationItem.hidesBackButton = shouldHideBack(step)
				configureCancel(for: step, in: nav)
			}
			return
		}

		// Determine push or pop
		if desired.count > current.count {
			// Push the new steps
			for step in desired.dropFirst(current.count) {
				let vc = UIHostingController(rootView: makeView(step))
				vc.title = titleFor(step)
				vc.navigationItem.hidesBackButton = shouldHideBack(step)
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
			if let step = desired.last {
				let vc = UIHostingController(rootView: makeView(step))
				vc.title = titleFor(step)
				vc.navigationItem.hidesBackButton = shouldHideBack(step)
				vcs[vcs.count - 1] = vc
				nav.setViewControllers(vcs, animated: false)
			}
		}

		nav.stepStack = desired
		if let step = desired.last { configureCancel(for: step, in: nav) }
	}

	private func visibleStack() -> [Step] {
		// Publicly expose the visible stack via currentStep and internal route depth.
		// Since route is private, we approximate by replaying from start until currentStep.
		// Coordinator advances one step at a time, so we can build from product config deterministically.
		// Build the same route here:
		var steps: [Step] = []
		if coordinator.config.showInstructions { steps.append(.instructions) }
		if coordinator.config.product.requiresDocInfo { steps.append(.documentInfo) }
		if coordinator.config.product.requiresDocFront {
			steps.append(.capture(.documentFront))
			steps.append(.preview(.documentFront))
		}
		if coordinator.config.product.requiresDocBack {
			steps.append(.capture(.documentBack))
			steps.append(.preview(.documentBack))
		}
		if coordinator.config.product.requiresSelfie {
			steps.append(.capture(.selfie))
			steps.append(.preview(.selfie))
		}
		steps.append(.processing)
		steps.append(.done)
		// Truncate up to currentStep
		if let idx = steps.firstIndex(of: coordinator.currentStep) {
			return Array(steps.prefix(idx + 1))
		}
		return [coordinator.currentStep]
	}

	private func configureCancel(for step: Step, in nav: _NavBoxController) {
		guard let top = nav.topViewController else { return }
		if step == .done {
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
