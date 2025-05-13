import Foundation

public struct Metadatum: Codable {
    let name: String
    let value: CodableValue
    let timestamp: String

    init(
        key: MetadataKey,
        value: CodableValue,
        date: Date = Date()
    ) {
        self.name = key.rawValue
        self.value = value
        self.timestamp = date.toISO8601WithMilliseconds()
    }
}
