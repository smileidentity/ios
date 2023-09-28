import Foundation

public struct HTTPHeader: Equatable {
    public var name: String
    public var value: String

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}

extension Array where Element == HTTPHeader {

    func toDictionary() -> [String: String] {
        reduce(into: [String: String]()) { $0[$1.name] = $1.value }
    }
}
