import Foundation

public enum SmartSelfieStatus: String, Codable {
  case approved
  case pending
  case rejected
  case unknown = "Unknown"
}
