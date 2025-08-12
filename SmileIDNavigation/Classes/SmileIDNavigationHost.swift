import SmileIDUI
import SwiftUI

public struct SmileIDNavigationHost: View {
	@Backport.StateObject private var coordinator = DefaultNavigationCoordinator()

	public init() {}

	public var body: some View {
		NavigationView {
			NavigationLink(
				destination: destinationView,
				isActive: Binding(
					get: { coordinator.currentDestination != .instructions },
					set: { _ in }
				)
			) {
				EmptyView()
			}
			.hidden()

			OrchestratedInstructionsScreen(coordinator: coordinator)
		}
		.navigationViewStyle(StackNavigationViewStyle())
	}

	@ViewBuilder
	private var destinationView: some View {
		switch coordinator.currentDestination {
		case .instructions:
			OrchestratedInstructionsScreen(coordinator: coordinator)
		case .capture:
			OrchestratedCaptureScreen(coordinator: coordinator)
		case .preview:
			OrchestratedPreviewScreen(coordinator: coordinator)
		case .processing:
			OrchestratedProcessingScreen(coordinator: coordinator)
		}
	}
}

#if DEBUG
	struct SmileIDNavigationHost_Previews: PreviewProvider {
		static var previews: some View {
			SmileIDNavigationHost()
		}
	}
#endif
