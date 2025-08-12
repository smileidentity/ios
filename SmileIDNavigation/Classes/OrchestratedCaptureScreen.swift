import SmileIDUI
import SwiftUI

public struct OrchestratedCaptureScreen: View {
	@ObservedObject var coordinator: DefaultNavigationCoordinator
	let scanType: ScanType

	public init(coordinator: DefaultNavigationCoordinator, scanType: ScanType = .selfie) {
		self.coordinator = coordinator
		self.scanType = scanType
	}

	public var body: some View {
		SmileIDCaptureScreen(
			scanType: scanType,
			onContinue: {
				coordinator.navigate(to: .preview)
			}
		)
		.navigationBarTitle("Capture")
	}
}

#if DEBUG
	struct OrchestratedCaptureScreen_Previews: PreviewProvider {
		static var previews: some View {
			Group {
				OrchestratedCaptureScreen(
					coordinator: DefaultNavigationCoordinator(),
					scanType: .selfie
				)
				.previewDisplayName("Selfie")

				OrchestratedCaptureScreen(
					coordinator: DefaultNavigationCoordinator(),
					scanType: .documentFront
				)
				.previewDisplayName("Document Front")
			}
		}
	}
#endif
