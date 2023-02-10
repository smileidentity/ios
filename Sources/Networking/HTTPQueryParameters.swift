import Foundation

public struct HTTPQueryParameters: Equatable {
    public var key: String
    public var value: [String]

    public init(key: String, values: [String]) {
        self.key = key
        self.value = values
    }

    public init (key: String, value: String) {
        self.key = key
        self.value = [value]
    }

}

extension Array: ExpressibleByDictionaryLiteral where Element == HTTPQueryParameters {

    public init(dictionaryLiteral elements: (String, [String])...) {
        self = elements.map {
            HTTPQueryParameters(key: $0.0, values: $0.1)
        }
    }
}
