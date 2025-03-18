import Foundation

public struct Metadatum: Codable {
    let name: String
    let value: AnyCodable

    init<T: Codable>(key: MetadataKey, value: T) {
        self.name = key.rawValue
        self.value = AnyCodable(value)
    }
}
