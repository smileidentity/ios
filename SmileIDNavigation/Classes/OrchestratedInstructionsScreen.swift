import SmileIDUI
import SwiftUI

public struct OrchestratedInstructionsScreen: View {
  @ObservedObject var coordinator: DefaultNavigationCoordinator

  public init(coordinator: DefaultNavigationCoordinator) {
    self.coordinator = coordinator
  }

  public var body: some View {
    SmileIDInstructionsScreen(
      onContinue: {
        coordinator.navigate(to: .capture)
      },
      onCancel: {
        coordinator.navigate(to: .capture)
      }
    )
  }
}

#if DEBUG
  struct OrchestratedInstructionsScreen_Previews: PreviewProvider {
    static var previews: some View {
      OrchestratedInstructionsScreen(
        coordinator: DefaultNavigationCoordinator()
      )
    }
  }
#endif
