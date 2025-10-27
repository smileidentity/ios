import SmileIDNavigation
import SwiftUI

private struct ActiveProduct: Identifiable {
  let id = UUID()
  let product: BusinessProduct
}

struct VerificationDemoView: View {
  var body: some View {
    SmileIDFlow { builder in
      builder.smileConfig { config in
        config.enableDebugMode = true
        config.allowOfflineMode = false
      }

      builder.screens {
        instructions { instructions in
          instructions.showAttribution = true
        }
        capture { capture in
          capture.mode = .selfie
          capture.selfie { selfie in
            selfie.allowAgentMode = false
          }
        }
        preview { preview in
          preview.allowRetake = true
        }
      }

      builder.onResult = { result in
        switch result {
        case .success(let data):
          print("Flow completed: \(data)")
        case .failure(let error):
          print("Flow failed: \(error)")
        }
      }
    }
  }

}

#if DEBUG
  #Preview {
    VerificationDemoView()
  }
#endif
