import Foundation

public struct PrepUploadRequest: Codable {
    var partnerParams: PartnerParams
    // Callback URL *must* be defined either within your Partner Portal or here
    var callbackUrl: String? = SmileID.callbackUrl
    var partnerId = SmileID.config.partnerId
    var sourceSdk = "ios"
    var sourceSdkVersion = SmileID.version
    var timestamp = String(Date().millisecondsSince1970)
    var signature = ""
    /// backend is broken needs these as strings
    /// I've also made this false until we have this properly
    /// documented and done on both android and iOS
    var allowNewEnroll = "false"
    var useEnrolledImage = false
    var retry = "false" /// backend is broken needs these as strings

    public init(
        partnerParams: PartnerParams,
        callbackUrl: String? = "",
        partnerId: String = SmileID.config.partnerId,
        sourceSdk: String = "ios",
        sourceSdkVersion: String = SmileID.version,
        timestamp: String = String(Date().millisecondsSince1970),
        signature: String = "",
        allowNewEnroll: String = "false",
        useEnrolledImage: Bool = false,
        retry: String = "false"
    ) {
        self.partnerParams = partnerParams
        self.callbackUrl = callbackUrl
        self.partnerId = partnerId
        self.sourceSdk = sourceSdk
        self.sourceSdkVersion = sourceSdkVersion
        self.timestamp = timestamp
        self.signature = signature
        self.allowNewEnroll = allowNewEnroll
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
