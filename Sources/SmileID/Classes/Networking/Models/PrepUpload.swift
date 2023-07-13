import Foundation

public struct PrepUploadRequest: Codable {
    var filename: String = "upload.zip"
    var partnerParams: PartnerParams
    var callbackUrl: String? = ""
    var partnerId = SmileID.config.partnerId
    var sourceSdk = "IOS"
    // TO-DO: Fetch version dynamically
    var sourceSdkVersion = "10.0.0-beta01"
    var timestamp = String(Date().millisecondsSince1970)
    var signature = ""
    var allowNewEnroll = "true" /// backend is broken needs these as strings
    var useEnrolledImage = false
    var retry = "false" /// backend is broken needs these as strings

    enum CodingKeys: String, CodingKey {
        case filename = "file_name"
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
