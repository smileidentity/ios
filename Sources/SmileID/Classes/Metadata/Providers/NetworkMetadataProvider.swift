import Combine
import Foundation
import Network

/// A class for determining the current network connection type (Wi-Fi, cellular, VPN, etc.)
class NetworkMetadata {
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
}

extension NetworkMetadata: MetadataProtocol {
    func collectMetadata() -> [Metadatum] {
        // Add network connection info
        var metadata = connectionEvents.map {
            Metadatum(
                key: .networkConnection,
                value: .string($0.type),
                date: $0.date
            )
        }
        return metadata
    }
}
