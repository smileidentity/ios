import Foundation

public struct Metadatum: Codable {
  let name: String
  let value: CodableValue
  let timestamp: String

  init(
    key: MetadataKey,
    value: CodableValue,
    date: Date = Date()
  ) {
    name = key.rawValue
    self.value = value
    timestamp = date.toISO8601WithMilliseconds()
  }
}
