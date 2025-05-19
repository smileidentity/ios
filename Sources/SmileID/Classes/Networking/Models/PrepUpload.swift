import Foundation

public struct PrepUploadRequest: Codable {
    public var partnerParams: PartnerParams
    // Callback URL *must* be defined either within your Partner Portal or here
    public var callbackUrl: String? = SmileID.callbackUrl
    public var allowNewEnroll: Bool = false
    public var partnerId = SmileID.config.partnerId
    public var metadata: [Metadatum]?
    public var sourceSdk = "ios"
    public var sourceSdkVersion = SmileID.version
    public var timestamp = Date().toISO8601WithMilliseconds()
    public var signature = ""
    public var useEnrolledImage = false
    public var retry: Bool = false

    public init(
        partnerParams: PartnerParams,
        callbackUrl: String? = SmileID.callbackUrl,
        allowNewEnroll: Bool = false,
        partnerId: String = SmileID.config.partnerId,
        metadata: [Metadatum]? = nil,
        sourceSdk: String = "ios",
        sourceSdkVersion: String = SmileID.version,
        timestamp: String = Date().toISO8601WithMilliseconds(),
        signature: String = "",
        useEnrolledImage: Bool = false,
        retry: Bool = false
    ) {
        self.partnerParams = partnerParams
        self.callbackUrl = callbackUrl
        self.allowNewEnroll = allowNewEnroll
        self.partnerId = partnerId
        self.metadata = metadata
        self.sourceSdk = sourceSdk
        self.sourceSdkVersion = sourceSdkVersion
        self.timestamp = timestamp
        self.signature = signature
        self.useEnrolledImage = useEnrolledImage
        self.retry = retry
    }

    enum CodingKeys: String, CodingKey {
        case partnerParams = "partner_params"
        case callbackUrl = "callback_url"
        case partnerId = "smile_client_id"
        case sourceSdk = "source_sdk"
        case allowNewEnroll = "allow_new_enroll"
        case useEnrolledImage = "use_enrolled_image"
        case sourceSdkVersion = "source_sdk_version"
        case timestamp
        case signature
        case retry
        case metadata
    }
}

public struct PrepUploadResponse: Codable {
    public var code: String
    public var refId: String
    public var uploadUrl: String
    public var smileJobId: String
    public var cameraConfig: String?

    enum CodingKeys: String, CodingKey {
        case code
        case refId = "ref_id"
        case uploadUrl = "upload_url"
        case smileJobId = "smile_job_id"
        case cameraConfig = "camera_config"
    }
}
