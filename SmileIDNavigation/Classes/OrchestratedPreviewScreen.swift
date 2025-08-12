import SmileIDUI
import SwiftUI

public struct OrchestratedPreviewScreen: View {
  @ObservedObject var coordinator: DefaultNavigationCoordinator

  public init(coordinator: DefaultNavigationCoordinator) {
    self.coordinator = coordinator
  }

  public var body: some View {
    SmileIDPreviewScreen(
      onContinue: {
        coordinator.navigate(to: .processing)
      },
      onRetry: {
        coordinator.navigateUp()
      }
    )
    .navigationBarTitle("Preview")
  }
}

#if DEBUG
  struct OrchestratedPreviewScreen_Previews: PreviewProvider {
    static var previews: some View {
      OrchestratedPreviewScreen(
        coordinator: DefaultNavigationCoordinator()
      )
    }
  }
#endif
