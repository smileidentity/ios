import Foundation

enum CodableValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([CodableValue])
    case object([String: CodableValue])

    // Encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let stringValue):
            try container.encode(stringValue)
        case .int(let intValue):
            try container.encode(intValue)
        case .double(let doubleValue):
            try container.encode(doubleValue)
        case .bool(let boolValue):
            try container.encode(boolValue)
        case .array(let arrayValue):
            try container.encode(arrayValue)
        case .object(let dictionaryValue):
            try container.encode(dictionaryValue)
        }
    }

    // Decoding
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()

        // We have to check for primitive types first (Int, Double, Bool)
        // Finally check for String as a fallback
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let objectValue = try? container.decode([String: CodableValue].self) {
            self = .object(objectValue)
        } else if let arrayValue = try? container.decode([CodableValue].self) {
            self = .array(arrayValue)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported JSON type for MetadataValue"
            )
        }
    }
}
