import Foundation
import StoreKit

func getBuildPlatform() -> String {
  let info = ProcessInfo.processInfo
  if info.isMacCatalystApp {
    return Platform.mac.rawValue
  }
  if #available(iOS 14.0, *) {
    if info.isiOSAppOnMac {
      return Platform.mac.rawValue
    }
  }
  if info.environment["SIMULATOR_MODEL_IDENTIFIER"] != nil {
    return Platform.simulator.rawValue
  }
  return Platform.iphone.rawValue
}

func getBuildReceipt() async -> String {
  await {
    if #available(iOS 16.0, *) {
      do {
        let result = try await AppTransaction.shared
        switch result {
        case .verified: return result.jwsRepresentation
        case .unverified: return "unknown"
        }
      } catch {
        return "unknown"
      }
    } else {
      return "unknown"
    }
  }()
}
