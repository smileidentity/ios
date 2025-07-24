import Foundation
import SmileIDSecurity

public struct SecurityInfo: Codable {
  public var timestamp: String
  public var mac: String
  public var files: [URL]? = nil

  public init(
    timestamp: String,
    mac: String,
    files: [URL]? = nil
  ) {
    self.timestamp = timestamp
    self.mac = mac
    self.files = files
  }

  enum CodingKeys: String, CodingKey {
    case timestamp
    case mac
  }

  public static func create(from files: [URL]) throws -> SecurityInfo {
    let timestamp = Date().toISO8601WithMilliseconds()
    let mac = try SmileIDCryptoManager.shared.sign(
      timestamp: timestamp,
      files: files
    )
    return SecurityInfo(
      timestamp: timestamp,
      mac: mac,
      files: files
    )
  }

  public func obfuscate() throws -> SecurityInfo {
    guard let files = self.files else {
      return self
    }
    try SmileIDCryptoManager.shared.encrypt(
      timestamp: self.timestamp,
      files: files
    )
    return self
  }

  public func encode() throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return try encoder.encode(self)
  }
}
