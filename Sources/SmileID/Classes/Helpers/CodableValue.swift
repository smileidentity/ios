import Foundation

enum CodableValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case date(Date)
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
        case .date(let dateValue):
            try container.encode(dateValue)
        case .array(let arrayValue):
            try container.encode(arrayValue)
        case .object(let dictionaryValue):
            try container.encode(dictionaryValue)
        }
    }

    // Decoding
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()

        // The order here matters as we're dealing with arbitrary data.
        // We have to check the double before the Date, because otherwise
        // a double value could turn into a Date. So only ISO 8601 string formatted
        // dates work, which sanitizeArray and sentry_sanitize use.
        // We must check String after Date, because otherwise we would turn a ISO 8601
        // string into a string and not a date.
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let dateValue = try? container.decode(Date.self) {
            self = .date(dateValue)
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
