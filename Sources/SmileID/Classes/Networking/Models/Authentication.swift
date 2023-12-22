import Foundation

/// The Auth Smile request. Auth Smile serves multiple purposes:
/// - It is used to fetch the signature needed for subsequent API requests
/// - It indicates the type of job that will being performed
/// - It is used to fetch consent information for the partner
///
///  - Parameters:
///    - jobType: The type of job that will be performed
///    - enrollment: Whether or not this is an enrollment job
///    - country: The country code of the country where the job is being performed. This value is
///       required in order to get back consent information for the partner
///    - idType: The type of ID that will be used for the job. This value is required in order to
///      get back consent information for the partner
///    - updateEnrolledImage: Whether or not the enrolled image should be updated with image
///      submitted for this job
///    - jobId: The job ID to associate with the job. Most often, this will correspond to a unique
///      Job ID within your own system. If not provided, a random job ID will be generated
///    - userId: The user ID to associate with the job. Most often, this will correspond to a unique
///      User ID within your own system. If not provided, a random user ID will be generated
///    - signature: Whether or not to fetch the signature for the job
///    - production: Whether or not to use the production environment
///    - partnerId: The partner ID
///    - authToken: The auth token from smile_config.json
public struct AuthenticationRequest: Codable {
    public var jobType: JobType?
    public var enrollment: Bool
    public var updateEnrolledImage: Bool?
    public var jobId: String?
    public var userId: String?
    public var country: String?
    public var idType: String?
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
        case country
        case idType = "id_type"
        case signature
        case production
        case partnerId = "partner_id"
        case authToken = "auth_token"
    }

    public init(
        jobType: JobType?,
        enrollment: Bool = false,
        updateEnrolledImage: Bool? = nil,
        jobId: String? = nil,
        userId: String? = nil,
        country: String? = nil,
        idType: String? = nil,
        signature: Bool = true,
        production: Bool = !SmileID.useSandbox,
        partnerId: String = SmileID.config.partnerId,
        authToken: String = SmileID.config.authToken
    ) {
        self.jobType = jobType
        self.enrollment = enrollment
        self.updateEnrolledImage = updateEnrolledImage
        self.jobId = jobId
        self.userId = userId
        self.country = country
        self.idType = idType
        self.signature = signature
        self.production = production
        self.partnerId = partnerId
        self.authToken = authToken
    }
}

public struct AuthenticationResponse: Codable {
    public var success: Bool
    public var signature: String
    public var timestamp: String
    public var partnerParams: PartnerParams
    public var consentInfo: ConsentInfo?

    public init(
        success: Bool,
        signature: String,
        timestamp: String,
        partnerParams: PartnerParams
    ) {
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
        case consentInfo = "consent_info"
    }
}

public struct ConsentInfo: Codable {
    public var canAccess: Bool
    public var consentRequired: Bool

    enum CodingKeys: String, CodingKey {
        case canAccess = "can_access"
        case consentRequired = "consent_required"
    }
}
