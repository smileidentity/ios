import Foundation
import StoreKit

struct BuildInfo {
  var platform: String
  var buildSource: String

  func toCodableObject() -> [String: CodableValue] {
    [
      "platform": .string(platform),
      "build_source": .string(buildSource)
    ]
  }
}

func getBuildInfo() async -> BuildInfo {
  var platform = Platform.iphone.rawValue
  let info = ProcessInfo.processInfo
  if info.isMacCatalystApp {
    platform = Platform.mac.rawValue
  }
  if #available(iOS 14.0, *) {
    if info.isiOSAppOnMac {
      platform = Platform.mac.rawValue
    }
  }
  if info.environment["SIMULATOR_MODEL_IDENTIFIER"] != nil {
    platform = Platform.simulator.rawValue
  }

  let buildSource: String = await {
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

  let buildInfo = BuildInfo(
    platform: platform,
    buildSource: buildSource
  )
  return buildInfo
}
