import Combine
import Foundation

public class LocalMetadata: ObservableObject {
    @Published var metadata: Metadata = .default()
    public init() {}

    func addMetadata(_ newMetadata: Metadatum) {
        metadata.items.append(newMetadata)
        objectWillChange.send()
    }
}
