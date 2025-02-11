import Foundation

public struct SecurityInfo: Codable {
    public var timestamp: String
    public var mac: String

    public init(
        timestamp: String,
        mac: String
    ) {
        self.timestamp = timestamp
        self.mac = mac
    }

    enum CodingKeys: String, CodingKey {
        case timestamp
        case mac
    }
}
