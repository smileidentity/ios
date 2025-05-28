import Combine
import Foundation
import Network

/// A class for determining the current network connection type (Wi-Fi, cellular, VPN, etc.)
class NetworkMetadata: MetadataProtocol {
    var provides: [MetadataKey] = [.networkConnection]

    private var monitor: NWPathMonitor?
    private var isRecording = false

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

    private var connectionEvents: [ConnectionEvent] = []

    func onStart() {
        // If we're already recording, then we don't start again
        if isRecording {
            return
        }
        isRecording = true

        // Clear previous history to start fresh recording session
        connectionEvents.removeAll()

        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor = NWPathMonitor()
        monitor?.start(queue: queue)
        monitor?.pathUpdateHandler = { [weak self] path in
            guard let self else { return }

            let newConnectionType = connectionType(for: path).rawValue
            if self.connectionEvents.last?.type != newConnectionType {
                self.connectionEvents.append(
                    ConnectionEvent(type: newConnectionType)
                )
            }
        }
    }

    func onStop() {
        isRecording = false
        monitor?.cancel()
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

    func collectMetadata() -> [Metadatum] {
        let metadata = connectionEvents.map {
            Metadatum(
                key: .networkConnection,
                value: .string($0.type),
                date: $0.date
            )
        }
        return metadata
    }

    func addMetadata(forKey: MetadataKey) {
        // no-op
    }

    func removeMetadata(forKey: MetadataKey) {
        switch forKey {
        case .networkConnection:
            connectionEvents.removeAll()
        default:
            // ignore the other cases
            break
        }
    }
}
