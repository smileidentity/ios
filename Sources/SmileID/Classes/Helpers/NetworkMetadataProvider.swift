import Foundation
import Network
import Combine

/// A class for determining the current network connection type (Wi-Fi, cellular, VPN, etc.)
class NetworkMetadataProvider {
    private let monitor: NWPathMonitor
    /// Array tracking connection types over time.
    private var connectionTypes: [String] = []

    init() {
        monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let newConnection = if path.usesInterfaceType(.wifi) {
                "wifi"
            } else if path.usesInterfaceType(.cellular) {
                "cellular"
            } else {
                "other"
            }

            if self.connectionTypes.last != newConnection {
                self.connectionTypes.append(newConnection)
            }
        }

        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}

extension NetworkMetadataProvider: MetadataProvider {
    func collectMetadata() -> [MetadataKey: String] {
        if let jsonData = try? JSONSerialization.data(withJSONObject: connectionTypes, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return [.networkConnection: jsonString]
        }
        return [.networkConnection: "unknown"]
    }
}
