import Foundation

public struct PrepUploadRequest: Codable {
    var partnerParams: PartnerParams
    // Callback URL *must* be defined either within your Partner Portal or here
    var callbackUrl: String? = SmileID.callbackUrl?.absoluteString ?? ""
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
    var code: String
    var refId: String
    var uploadUrl: String
    var smileJobId: String
    var cameraConfig: String?

    enum CodingKeys: String, CodingKey {
        case code
        case refId = "ref_id"
        case uploadUrl = "upload_url"
        case smileJobId = "smile_job_id"
        case cameraConfig = "camera_config"
    }
}
