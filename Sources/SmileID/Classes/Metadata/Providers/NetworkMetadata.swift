import Combine
import Foundation
import Network

/// A class for determining the current network connection type (Wi-Fi, cellular, VPN, etc.)
class NetworkMetadata {
    private struct ConnectionEvent {
        let type: String
        let date: Date = Date()
    }

    private enum NetworkConnection: String {
        case wifi = "wifi"
        case cellular = "cellular"
        case other = "other"
        case unknown = "unknown"
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
                type: connectionType(for: monitor.currentPath).rawValue
            )
        )

        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }

            let newConnectionType = connectionType(for: path).rawValue
            if self.connectionEvents.last?.type != newConnectionType {
                self.connectionEvents.append(
                    ConnectionEvent(type: newConnectionType)
                )
            }
        }
    }

    private func connectionType(for path: NWPath) -> NetworkConnection {
        if path.usesInterfaceType(.wifi) {
            return NetworkConnection.wifi
        } else if path.usesInterfaceType(.cellular) {
            return NetworkConnection.cellular
        } else {
            return NetworkConnection.other
        }
    }

    deinit {
        monitor.cancel()
    }
}

extension NetworkMetadata: MetadataProtocol {
    func collectMetadata() -> [Metadatum] {
        // Add network connection info
        let metadata = connectionEvents.map {
            Metadatum(
                key: .networkConnection,
                value: .string($0.type),
                date: $0.date
            )
        }
        return metadata
    }
}
