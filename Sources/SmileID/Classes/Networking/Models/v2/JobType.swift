import Foundation

public enum JobTypeV2: String, Codable {
    case smartSelfieAuthentication = "smart_selfie_authentication"
    case smartSelfieEnrollment = "smart_selfie_enrollment"
    case unknown = "Unknown"
}
