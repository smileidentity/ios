import CFNetwork
import Foundation

/// Checks if VPN connection is active by examining network interfaces
/// - Returns: Boolean indicating if VPN is detected.
func isVPNActive() -> Bool {
    guard let cfDict = CFNetworkCopySystemProxySettings() else { return false }
    let nsDict = cfDict.takeRetainedValue() as NSDictionary
    guard let keys = nsDict["__SCOPED__"] as? NSDictionary else { return false }

    let vpnInterfacePrefixes = ["tap", "tun", "ppp", "ipsec", "utun"]

    if let interfaces = keys.allKeys as? [String] {
        return interfaces.contains { interface in
            vpnInterfacePrefixes.contains { prefix in
                interface.contains(prefix)
            }
        }
    }
    return false
}
