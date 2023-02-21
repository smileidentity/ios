// swiftlint:disable force_cast
import Foundation

public struct PrepUploadRequest: Codable {
    var filename: String
    var partnerParams: PartnerParams
    var callbackUrl: String?
    var partnerId = SmileIdentity.config!.partnerId
    var sourceSdk = "iOS"
    // TO-DO: Fetch version dynamically
    var sourceSdkVersion = "0.1.0"
    var timestamp = String(Date().millisecondsSince1970)
    var signature = ""

    enum CodingKeys: String, CodingKey {
        case filename
        case partnerParams = "partner_params"
        case callbackUrl = "callback_url"
        case partnerId = "smile_client_id"
        case sourceSdk = "source_sdk"
        case sourceSDKVersion = "source_sdk_version"
        case timestamp
        case signature
    }
}

public struct PrepUploadResponse: Codable {
    var code: Int
    var refId: String
    var uploadUrl: String
    var smileJobId: String
    var cameraConfig: String?
}
// swiftlint:enable force_cast
