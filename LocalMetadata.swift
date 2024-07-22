import Foundation

public class LocalMetadata: ObservableObject {
    @Published var metadata: Metadata = Metadata.default()
}
