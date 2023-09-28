import Foundation

public struct HTTPQueryParameters: Equatable {
    public var key: String
    public var values: [String]

    public init(key: String, values: [String]) {
        self.key = key
        self.values = values
    }

    public init(key: String, value: String) {
        self.key = key
        values = [value]
    }

}

extension Array: ExpressibleByDictionaryLiteral where Element == HTTPQueryParameters {

    public init(dictionaryLiteral elements: (String, [String])...) {
        self = elements.map {
            HTTPQueryParameters(key: $0.0, values: $0.1)
        }
    }
}
