import SmileIDUI
import SwiftUI

struct OrchestratedBuilderInstructionsScreen: View {
  let configuration: InstructionsScreenConfiguration
  @EnvironmentObject private var navigationManager: FlowNavigationManager

  var body: some View {
    SmileIDInstructionsScreen(
      onContinue: navigateForward,
      onCancel: {})
  }

  private func navigateForward() {
    let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
    navigationManager.navigateToNext(
      currentScreenType: .instructions,
      result: .consent(granted: true, timestamp: timestamp)
    )
  }
}
