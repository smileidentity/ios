import Foundation

public struct PrepUploadRequest: Codable {
    var filename: String = "archive.zip"
    var partnerParams: PartnerParams
    var callbackUrl: String? = "https://example.com"
    var partnerId = SmileIdentity.config.partnerId
    var sourceSdk = "iOS"
    // TO-DO: Fetch version dynamically
    var sourceSdkVersion = "0.1.0"
    var timestamp = String(Date().millisecondsSince1970)
    var signature = ""

    enum CodingKeys: String, CodingKey {
        case filename = "file_name"
        case partnerParams = "partner_params"
        case callbackUrl = "callback_url"
        case partnerId = "smile_client_id"
        case sourceSdk = "source_sdk"
        case sourceSdkVersion = "source_sdk_version"
        case timestamp
        case signature
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
