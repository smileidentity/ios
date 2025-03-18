import Foundation

public struct Metadatum: Codable {
    let name: String
    let value: AnyCodable

    init<T: Codable>(key: MetadataKey, value: T) {
        self.name = key.rawValue
        self.value = AnyCodable(value)
    }

    enum CodingKeys: String, CodingKey {
        case name, value
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.value, forKey: .value)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        value = try container.decode(AnyCodable.self, forKey: .value)
    }
}
