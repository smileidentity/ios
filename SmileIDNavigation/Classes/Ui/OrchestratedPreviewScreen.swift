import SwiftUI

struct OrchestratedBuilderPreviewScreen: View {
  let configuration: PreviewScreenConfiguration
  @EnvironmentObject private var navigationManager: FlowNavigationManager

  var body: some View {
    VStack(spacing: 24) {
      Text("Preview")
      Text(configuration.allowRetake ? "Retake Allowed" : "Retake Disabled")
        .font(.footnote)
        .foregroundColor(.secondary)
      HStack(spacing: 16) {
        if configuration.allowRetake {
          Button("Retake") {
            navigationManager.navigateBack()
          }
        }
        Button("Finish") {
          navigationManager.navigateToNext(currentScreenType: .preview)
        }
      }
    }
    .padding()
  }
}
