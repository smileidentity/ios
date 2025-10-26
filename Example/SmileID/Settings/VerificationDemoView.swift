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
                builder.screens { screens in
                    screens.screen { screen in
                        screen.instructions { instructions in
                            instructions.showAttribution = true
                        }
                    }
                    
                    screens.screen { screen in
                        screen.capture { capture in
                            capture.mode = .selfie
                            capture.selfie { selfie in
                                selfie.allowAgentMode = false
                            }

                        }
                    }
                    
                    screens.screen { screen in
                        screen.preview { preview in
                            preview.allowRetake = true
                        }
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
