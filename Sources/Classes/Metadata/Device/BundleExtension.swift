import Foundation

extension Bundle {
  /// Gets the host application name and version in the format "App Name v1.0.0"
  var hostApplicationInfo: String {
    // Get the app name (display name or bundle name)
    let appName =
      object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? object(forInfoDictionaryKey: "CFBundleName") as? String

    // Get the app version
    let appVersion = object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String

    if let appName, let appVersion {
      return "\(appName) v\(appVersion)"
    } else if let appName {
      return appName
    } else {
      return "unknown"
    }
  }
}
