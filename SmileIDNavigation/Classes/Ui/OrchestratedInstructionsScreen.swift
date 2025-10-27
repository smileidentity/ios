import SwiftUI

struct OrchestratedBuilderInstructionsScreen: View {
  let configuration: InstructionsScreenConfiguration
  @EnvironmentObject private var navigationManager: FlowNavigationManager

  var body: some View {
    VStack(spacing: 24) {
      Text("Instructions")
      if configuration.showAttribution {
        Text("Powered by SmileID")
          .font(.footnote)
          .foregroundColor(.secondary)
      }
      // Custom continue button or default
      if let custom = configuration.continueButton {
        custom { navigateForward() }
      } else {
        Button(action: navigateForward) {
          Text("Continue")
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(10)
        }
        .padding(.horizontal)
      }
    }
    .padding()
  }

  private func navigateForward() {
    let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
    navigationManager.navigateToNext(
      currentScreenType: .instructions,
      result: .consent(granted: true, timestamp: timestamp)
    )
  }
}
