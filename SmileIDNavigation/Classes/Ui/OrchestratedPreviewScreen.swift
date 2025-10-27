import SmileIDUI
import SwiftUI

struct OrchestratedBuilderPreviewScreen: View {
  let configuration: PreviewScreenConfiguration
  @EnvironmentObject private var navigationManager: FlowNavigationManager

  var body: some View {
      SmileIDPreviewScreen(
        onContinue: {
            navigationManager.navigateToNext(currentScreenType: .preview)
        },
        onRetry: {

        }
      )
  }
}
