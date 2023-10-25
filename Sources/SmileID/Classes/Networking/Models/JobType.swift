import Foundation

public enum JobType: Int, Codable {
    case biometricKyc = 1
    case smartSelfieAuthentication = 2
    case smartSelfieEnrollment = 4
    case enhancedKyc = 5
    case documentVerification = 6
    case bvn = 7
    case enhancedDocumentVerification = 11
}
