import Combine
import Foundation
import Network

/// A class for determining the current network connection type (Wi-Fi, cellular, VPN, etc.)
class NetworkMetadataProvider {
    private struct ConnectionEvent {
        let type: String
        let date: Date = Date()
    }

    private let monitor: NWPathMonitor
    /// Array tracking connection types over time.
    private var connectionEvents: [ConnectionEvent] = []

    init() {
        monitor = NWPathMonitor()

        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)

        // Initialize with current connection state
        connectionEvents.append(
            ConnectionEvent(
                type: connectionType(for: monitor.currentPath)
            )
        )

        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }

            let newConnection = connectionType(for: path)
            if self.connectionEvents.last?.type != newConnection {
                self.connectionEvents.append(
                    ConnectionEvent(type: newConnection)
                )
            }
        }
    }

    private func connectionType(for path: NWPath) -> String {
        if path.usesInterfaceType(.wifi) {
            return "wifi"
        } else if path.usesInterfaceType(.cellular) {
            return "cellular"
        } else {
            return "other"
        }
    }

    deinit {
        monitor.cancel()
    }

    /// Checks if the system has an HTTP, HTTPS, or SOCKS proxy configured
    private func isProxyDetected() -> Bool {
        // Attempt to copy the proxy settings dictionary
        guard
            let proxySettings = CFNetworkCopySystemProxySettings()?.takeRetainedValue()
                as? [String: Any]
        else {
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

    /// Checks if VPN connection is active by examining network interfaces
    /// - Returns: Boolean indicating if VPN is detected.
    private func isVPNActive() -> Bool {
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
}

extension NetworkMetadataProvider: MetadataProvider {
    func collectMetadata() -> [Metadatum] {
        // Add network connection info
        var metadata = connectionEvents.map {
            Metadatum(
                key: .networkConnection,
                value: .string($0.type),
                date: $0.date
            )
        }

        // Add proxy detection info
        metadata.append(
            Metadatum(
                key: .proxyDetected,
                value: .bool(isProxyDetected())
            )
        )
        // Add VPN info
        metadata.append(
            Metadatum(
                key: .vpnDetected,
                value: .bool(isVPNActive())
            )
        )

        return metadata
    }
}
