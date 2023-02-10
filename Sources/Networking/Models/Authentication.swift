import Foundation

public struct AuthenticationRequest: Codable {
    var jobType: JobType
    var enrollment: Bool
    var updateEnrolledImage: Bool?
    var jobId: String?
    var userId: String?
    internal var signature = true
    internal var production = SmileIdentity.instance.useSandbox
    internal var partnerId = SmileIdentity.instance.config?.partnerId ?? ""
    internal var authToken = SmileIdentity.instance.config?.authToken ?? ""
}

public extension AuthenticationRequest {
    init(jobType: JobType, enrollment: Bool, updateEnrolledImage: Bool, jobId: String, userId: String) {
        self.init(jobType: jobType, enrollment: enrollment, updateEnrolledImage: updateEnrolledImage, jobId: jobId, userId: userId, signature: true)
    }
}

public struct AuthenticationResponse: Decodable {
    public var success: Bool
    public var signature: String
    public var timestamp: String
    public var partnerParams: String
}
