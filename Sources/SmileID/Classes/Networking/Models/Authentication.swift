import Foundation

public struct AuthenticationRequest: Codable {
    public var jobType: JobType
    public var enrollment: Bool
    public var updateEnrolledImage: Bool?
    public var jobId: String?
    public var userId: String?
    public var signature = true
    public var production = !SmileID.useSandbox
    public var partnerId = SmileID.config.partnerId
    public var authToken = SmileID.config.authToken

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

    public init(jobType: JobType,
                enrollment: Bool,
                updateEnrolledImage: Bool? = nil,
                jobId: String?,
                userId: String?,
                signature: Bool = true,
                production: Bool = !SmileID.useSandbox,
                partnerId: String = SmileID.config.partnerId,
                authToken: String = SmileID.config.authToken) {
        self.jobType = jobType
        self.enrollment = enrollment
        self.updateEnrolledImage = updateEnrolledImage
        self.jobId = jobId
        self.userId = userId
        self.signature = signature
        self.production = production
        self.partnerId = partnerId
        self.authToken = authToken
    }
}

public struct AuthenticationResponse: Decodable {
    public var success: Bool
    public var signature: String
    public var timestamp: String
    public var partnerParams: PartnerParams

    public init(success: Bool,
                signature: String,
                timestamp: String,
                partnerParams: PartnerParams) {
        self.success = success
        self.signature = signature
        self.timestamp = timestamp
        self.partnerParams = partnerParams
    }

    enum CodingKeys: String, CodingKey {
        case success
        case signature
        case timestamp
        case partnerParams = "partner_params"
    }
}
