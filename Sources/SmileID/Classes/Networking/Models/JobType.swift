import Foundation

public enum JobType: Int, Codable {
    case smartSelfieAuthentication = 2
    case smartSelfieEnrollment = 4
    case enhancedKyc = 5
    case documentVerification = 6
}
