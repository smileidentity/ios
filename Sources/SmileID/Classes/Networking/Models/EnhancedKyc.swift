import Foundation

public struct EnhancedKycRequest: Codable {
    public var country: String
    public var idType: String
    public var idNumber: String
    public var firstName: String?
    public var middleName: String?
    public var lastName: String?
    public var dob: String?
    public var phoneNumber: String?
    public var bankCode: String?
    public var callbackUrl: String?
    public var partnerParams: PartnerParams
    public var signature = ""
    public var timestamp = String(Date().millisecondsSince1970)
    public var partnerId: String = SmileID.config.partnerId
    public var sourceSdk: String = "ios"
    public var sourceSdkVersion = SmileID.version

    enum CodingKeys: String, CodingKey {
        case country
        case idType = "id_type"
        case idNumber = "id_number"
        case firstName = "first_name"
        case middleName = "middle_name"
        case lastName = "last_name"
        case dob
        case phoneNumber = "phone_number"
        case bankCode = "bank_code"
        case callbackUrl = "callback_url"
        case partnerParams = "partner_params"
        case partnerId = "partner_id"
        case sourceSdk = "source_sdk"
        case sourceSdkVersion = "source_sdk_version"
        case timestamp
        case signature
    }
}

public struct EnhancedKycAsyncResponse: Codable {
    public var success: Bool
}
