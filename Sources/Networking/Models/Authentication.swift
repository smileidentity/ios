import Foundation

public struct AuthenticationRequest: Codable {
    var jobType: String
    var enrollment: Bool
    var updateEnrolledImage: Bool?
    var jobId: String?
    var userId: String?
    internal var signature = true
    internal var production = !SmileIdentity.useSandbox
    internal var partnerId = SmileIdentity.config!.partnerId
    internal var authToken = SmileIdentity.config!.authToken

    enum CodingKeys: String, CodingKey {
        case jobType = "job_type"
        case enrollment
        case updateEnrolledImage = "update_enrolled_image"
        case jobId = "job_id"
        case userId = "user_id"
        case signature
        case production
        case partnerId = "partner_id"
        case authToken = "auth_token"
    }
}

public extension AuthenticationRequest {
    init(jobType: JobType, enrollment: Bool, updateEnrolledImage: Bool, jobId: String, userId: String) {
        self.init(jobType: jobType.rawValue, enrollment: enrollment, updateEnrolledImage: updateEnrolledImage, jobId: jobId, userId: userId, signature: true)
    }

    init(jobType: JobType, enrollment: Bool, userId: String) {
        self.init(jobType: jobType.rawValue, enrollment: enrollment, updateEnrolledImage: nil, jobId: nil, userId: userId, signature: true)
    }
}

public struct AuthenticationResponse: Decodable {
    public var success: Bool
    public var signature: String
    public var timestamp: String

    enum CodingKeys: String, CodingKey {
        case success
        case signature
        case timestamp
    }
}
