import Combine
import Foundation

public class LocalMetadata: ObservableObject {
    @Published var metadata: Metadata = .default()
    private var notificationToken: NSObjectProtocol?
    
    public init() {
        // Register for network connection type changes
        notificationToken = NotificationCenter.default.addObserver(
            forName: .networkConnectionTypeDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.updateNetworkConnectionMetadata()
        }
    }
    
    deinit {
        if let token = notificationToken {
            NotificationCenter.default.removeObserver(token)
        }
    }

    func addMetadata(_ newMetadata: Metadatum) {
        metadata.items.append(newMetadata)
        objectWillChange.send()
    }

    /// Updates the network connection metadata item with the current connection type
    private func updateNetworkConnectionMetadata() {
        // Remove existing network_connection metadata items
        metadata.items.removeAll { metadatum in
            metadatum.name == "network_connection"
        }

        // Add a new one with the current connection type
        metadata.items.append(Metadatum.NetworkConnection())
        objectWillChange.send()
    }
}
