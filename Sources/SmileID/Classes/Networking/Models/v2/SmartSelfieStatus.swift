import Foundation

public enum SmartSelfieStatus: String, Codable {
    case Approved = "approved"
    case Pending = "pending"
    case Rejected = "rejected"
    case Unknown = "Unknown"
}
