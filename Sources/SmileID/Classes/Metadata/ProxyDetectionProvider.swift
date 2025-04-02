import CFNetwork
import Foundation

class ProxyDetectionProvider {
    private func isProxyDetected() -> Bool {
        // Get the dictionary of proxy settings
        guard let proxySettings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any] else {
            return false
        }

        // Check for HTTP proxy
        if let httpProxy = proxySettings["HTTPProxy"] as? String,
            !httpProxy.isEmpty
        {
            return true
        }

        // Check for HTTPs proxy
        if let httpsProxy = proxySettings["HTTPSProxy"] as? String,
            !httpsProxy.isEmpty
        {
            return true
        }

        // Check for proxy enabled status
        if let httpEnabled = proxySettings["HTTPEnable"] as? Int,
            httpEnabled == 1
        {
            return true
        }

        if let httpsEnabled = proxySettings["HTTPSEnable"] as? Int,
            httpsEnabled == 1
        {
            return true
        }

        // Additionally check for VPN interface
        return isVPNActive()
    }

    /// Checks if a VPN connection is active by examining network interfaces
    /// - Returns: Boolean indicating if VPN is detected
    private func isVPNActive() -> Bool {
        guard let cfDict = CFNetworkCopySystemProxySettings()?.takeRetainedValue() else {
            return false
        }

        guard let nsDict = cfDict as? [String: Any],
            let keys = nsDict["__SCOPED__"] as? [String] else {
            return false
        }

        // Look for network interfaces typically used by VPNs
        let vpnProtocols = ["tap", "tun", "ppp", "ipsec", "utun"]
        for key in keys {
            for protocolName in vpnProtocols {
                if key.lowercased().contains(protocolName) {
                    return true
                }
            }
        }

        return false
    }
}

extension ProxyDetectionProvider: MetadataProvider {
    func collectMetadata() -> [MetadataKey: String] {
        let proxyDetected = isProxyDetected()
        return [.proxyDetected: proxyDetected ? "true" : "false"]
    }
}
