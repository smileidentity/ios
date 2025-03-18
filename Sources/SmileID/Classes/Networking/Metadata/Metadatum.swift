import Foundation

struct Metadatum: Encodable {
    let name: String
    let value: AnyEncodable

    init<T: Encodable>(name: String, value: T) {
        self.name = name
        self.value = AnyEncodable(value)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.value, forKey: .value)
    }

    enum CodingKeys: String, CodingKey {
        case name, value
    }
}
