import Foundation

struct AuthenticationRequest: Codable {
    var jobType: JobType
    var enrollment: Bool
    var updateEnrolledImage: Bool?
    var jobId: String?
    var userId: String?
    var signature = true
    var production = SmileIdentity.instance.useSandbox
    var partnerId = SmileIdentity.instance.config?.partnerId ?? ""
    var authToken = SmileIdentity.instance.config?.authToken ?? ""
}

struct AuthenticationResponse: Decodable {
    var success: Bool
    var signature: String
    var timestamp: String
    var partnerParams: String
}
