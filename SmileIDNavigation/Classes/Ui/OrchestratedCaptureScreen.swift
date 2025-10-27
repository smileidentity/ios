import SmileIDUI
import SwiftUI

// Simplified capture screen aligning with FlowNavigationManager API.
// Uses navigateToNext to advance flow; configuration is required (non-optional).
struct OrchestratedBuilderCaptureScreen: View {
  let configuration: CaptureScreenConfiguration
  @EnvironmentObject private var navigationManager: FlowNavigationManager

  var body: some View {
      SmileIDCaptureScreen(
        scanType: .documentBack,
        onContinue: {
            // Advance to next screen without a capture result (placeholder)
            navigationManager.navigateToNext(currentScreenType: .capture)
        }
        )
      }
}
