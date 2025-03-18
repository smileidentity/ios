import Foundation

struct AnyCodable: Codable {
    let value: Any

    init<T: Codable>(_ value: T) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        // Try decoding the most common types:
        if let boolVal = try? container.decode(Bool.self) {
            self.value = boolVal
        } else if let intVal = try? container.decode(Int.self) {
            self.value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            self.value = doubleVal
        } else if let stringVal = try? container.decode(String.self) {
            self.value = stringVal
        } else if let arrayVal = try? container.decode([AnyCodable].self) {
            self.value = arrayVal.map { $0.value }
        } else if let dicVal = try? container.decode([String: AnyCodable].self) {
            self.value = dicVal.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "AnyCodable value cannot be decoded"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self.value {
        case let boolVal as Bool:
            try container.encode(boolVal)
        case let intVal as Int:
            try container.encode(intVal)
        case let doubleVal as Double:
            try container.encode(doubleVal)
        case let stringVal as String:
            try container.encode(stringVal)
        case let arrayVal as [AnyCodable]:
            let codableArray = arrayVal.map { AnyCodable($0) }
            try container.encode(codableArray)
        case let dictVal as [String: AnyCodable]:
            let codableDict = dictVal.mapValues { AnyCodable($0) }
            try container.encode(codableDict)
        default:
            let context = EncodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "AnyCodable value cannot be encoded"
            )
            throw EncodingError.invalidValue(self.value, context)
        }
    }
}
