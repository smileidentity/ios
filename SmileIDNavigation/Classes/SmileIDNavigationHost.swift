import SmileIDUI
import SwiftUI

public struct SmileIDNavigationHost: View {
  @ObservedObject private var coordinator = DefaultNavigationCoordinator()

  public init() {}

  public var body: some View {
    NavigationView {
			ZStack {
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
				
				SmileIDInstructionsScreen(
					onContinue: {
						coordinator.navigate(to: .capture)
					},
					onCancel: {}
				)
			}
    }
    .navigationViewStyle(StackNavigationViewStyle())
  }

  @ViewBuilder
  private var destinationView: some View {
    switch coordinator.currentDestination {
    case .instructions:
			SmileIDInstructionsScreen(
				onContinue: {
					coordinator.navigate(to: .capture)
				},
				onCancel: {}
			)
    case .capture:
			SmileIDCaptureScreen(
				scanType: .selfie,
				onContinue: {
					coordinator.navigate(to: .preview)
				}
			)
    case .preview:
			SmileIDPreviewScreen(
				onContinue: {
					coordinator.navigate(to: .processing)
				},
				onRetry: {
					coordinator.navigateUp()
				}
			)
    case .processing:
			SmileIDProcessingScreen(
				onContinue: {
					coordinator.popToRoot()
				},
				onCancel: {
					coordinator.navigateUp()
				}
			)
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
