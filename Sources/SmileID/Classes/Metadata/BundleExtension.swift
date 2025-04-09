import Foundation

extension Bundle {
    /// Gets the host application name and version in the format "App Name v1.0.0"
    var hostApplicationInfo: String {
        // Get the app name (display name or bundle name)
        let appName = self.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String 
            ?? self.object(forInfoDictionaryKey: "CFBundleName") as? String 
            ?? "Unknown App"

        // Get the app version
        let appVersion = self.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String 
            ?? "Unknown Version"

        // Return in format "App Name v1.0.0"
        return "\(appName) v\(appVersion)"
    }
}
