import Foundation
import Network

/// A class for determining the current network connection type (Wi-Fi, cellular, VPN, etc.)
public class NetworkConnectionProvider {
    public enum ConnectionType: String {
        case wifi
        case cellular
        case vpn
        case wired
        case loopback
        case other
        case unknown

        public var description: String {
            return rawValue
        }
    }

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkConnectionProvider")
    private var currentConnectionType: ConnectionType = .unknown

    public static let shared = NetworkConnectionProvider()

    private init() {
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.updateConnectionType(path: path)
        }
        monitor.start(queue: queue)
    }

    private func stopMonitoring() {
        monitor.cancel()
    }

    private func updateConnectionType(path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            currentConnectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            currentConnectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            currentConnectionType = .wired
        } else if path.usesInterfaceType(.loopback) {
            currentConnectionType = .loopback
        } else if let vpnStatus = isVPNActive(), vpnStatus {
            currentConnectionType = .vpn
        } else if path.status == .satisfied {
            currentConnectionType = .other
        } else {
            currentConnectionType = .unknown
        }
    }

    private func isVPNActive() -> Bool? {
        let vpnProtocolsKeyIDs = [
            "tap", "tun", "ppp", "ipsec", "utun",
        ]

        let networkInterfaces = NetworkConnectionProvider.getAllNetworkInterfaces()
        guard !networkInterfaces.isEmpty else {
            return nil
        }

        for interface in networkInterfaces {
            for protocolKeyID in vpnProtocolsKeyIDs {
                if interface.lowercased().contains(protocolKeyID) {
                    return true
                }
            }
        }

        return false
    }

    private static func getAllNetworkInterfaces() -> [String] {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return []
        }
        defer { freeifaddrs(ifaddr) }

        var interfaces: [String] = []

        // Make `ptr` an optional so we can safely check for `nil`
        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let current = ptr {
            // Convert the interface name from a C string to a Swift string
            if let cString = current.pointee.ifa_name {
                interfaces.append(String(cString: cString))
            }
            // Move to the next interface in the linked list
            ptr = current.pointee.ifa_next
        }

        return interfaces
    }

    /// Returns the current connection type as a string
    public func getCurrentConnectionType() -> String {
        return currentConnectionType.description
    }

    /// Returns whether the device is currently connected to a network
    public var isConnected: Bool {
        return monitor.currentPath.status == .satisfied
    }
}
