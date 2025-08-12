import SmileIDUI
import SwiftUI

public struct OrchestratedProcessingScreen: View {
	@ObservedObject var coordinator: DefaultNavigationCoordinator

	public init(coordinator: DefaultNavigationCoordinator) {
		self.coordinator = coordinator
	}

	public var body: some View {
		SmileIDProcessingScreen(
			onContinue: {
				coordinator.popToRoot()
			},
			onCancel: {
				coordinator.navigateUp()
			}
		)
		.navigationBarTitle("Processing")
	}
}

#if DEBUG
	struct OrchestratedProcessingScreen_Previews: PreviewProvider {
		static var previews: some View {
			OrchestratedProcessingScreen(
				coordinator: DefaultNavigationCoordinator()
			)
		}
	}
#endif
