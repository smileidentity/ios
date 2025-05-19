import Foundation
import SmileIDSecurity

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

func createSecurityInfo(files: [URL]) throws -> Data {
    let timestamp = Date().toISO8601WithMilliseconds()
    let mac = try SmileIDCryptoManager.shared.sign(
        timestamp: timestamp,
        files: files
    )
    let securityInfo = SecurityInfo(
        timestamp: timestamp,
        mac: mac
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return try encoder.encode(securityInfo)
}
