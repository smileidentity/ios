import Foundation

public enum JobTypeV2: String, Codable {
    case SmartSelfieAuthentication = "smart_selfie_authentication"
    case SmartSelfieEnrollment = "smart_selfie_enrollment"
    case Unknown = "Unknown"
}
