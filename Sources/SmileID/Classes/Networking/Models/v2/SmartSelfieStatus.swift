import Foundation

public enum SmartSelfieStatus: String, Codable {
    case approved = "approved"
    case pending = "pending"
    case rejected = "rejected"
    case unknown = "Unknown"
}
