
struct BuildInfo {
  var platform: String
  var buildSource: String

  func toCodableObject() -> [String: CodableValue] {
    [
      "platform": .string(platform),
      "build_source": .string(buildSource),
    ]
  }
}

func getBuildInfo() -> BuildInfo {
  let platform = Platform.iphone.rawValue
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
  let buildSource = Bundle.main.appStoreReceiptURL
  let buildInfo = BuildInfo(
    platform: platform,
    buildSource: buildSource
  )
  print(buildInfo)
  return buildInfo
}
