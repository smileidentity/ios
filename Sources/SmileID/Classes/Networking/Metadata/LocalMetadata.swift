import Combine
import Foundation

public class LocalMetadata: ObservableObject {
    @Published var metadata: Metadata = .default()
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        // Subscribe to network connection type changes
        NetworkConnectionProvider.shared.$connectionType
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                // Update metadata when connection type changes
                self?.updateNetworkConnectionMetadata()
            }
            .store(in: &cancellables)
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
