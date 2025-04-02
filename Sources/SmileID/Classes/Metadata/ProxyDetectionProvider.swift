import CFNetwork
import Foundation

class ProxyDetectionProvider {
    /// Checks if the system has an HTTP, HTTPS, or SOCKS proxy configured
    private func isProxyDetected() -> Bool {
        // Attempt to copy the proxy settings dictionary
        guard let proxySettings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any] else {
            return false
        }

        // Check if there is an HTTP proxy set
        if let httpProxy = proxySettings["HTTPProxy"] as? String,
            !httpProxy.isEmpty {
            return true
        }

        // Check if there is an HTTPS proxy set
        if let httpsProxy = proxySettings["HTTPSProxy"] as? String,
            !httpsProxy.isEmpty {
            return true
        }

        // Check if there is a SOCKS proxy set.
        if let socksProxy = proxySettings["SOCKSProxy"] as? String,
            !socksProxy.isEmpty {
            return true
        }

        // Check for proxy enabled status.
        if let httpEnabled = proxySettings["HTTPEnable"] as? Int,
            httpEnabled == 1 {
            return true
        }

        if let httpsEnabled = proxySettings["HTTPSEnable"] as? Int,
            httpsEnabled == 1 {
            return true
        }

        if let socksEnabled = proxySettings["SOCKSEnabled"] as? Int,
            socksEnabled == 1 {
            return true
        }

        // If we haven't found any enabled proxy, return false.
        return false
    }
}

extension ProxyDetectionProvider: MetadataProvider {
    func collectMetadata() -> [MetadataKey: String] {
        let proxyDetected = isProxyDetected()
        return [.proxyDetected: proxyDetected ? "true" : "false"]
    }
}
