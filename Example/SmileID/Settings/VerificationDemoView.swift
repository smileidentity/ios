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
                
                builder.onResult = { result in
                    switch result {
                    case .success(let data):
                        print("Flow completed: \(data)")
                    case .failure(let error):
                        print("Flow failed: \(error)")
                    }
                }
                
                builder.screens {
                    screen { $0.instructions { instructions in
                        instructions.showAttribution = true
                    }}
                    
                    screen { $0.capture { capture in
                        capture.mode = .selfie
                        capture.selfie { selfie in
                            selfie.allowAgentMode = false
                        }
                    }}
                    
                    screen { $0.preview { preview in
                        preview.allowRetake = true
                    }}
                }
            }
        }
  }

#if DEBUG
  #Preview {
    VerificationDemoView()
  }
#endif
