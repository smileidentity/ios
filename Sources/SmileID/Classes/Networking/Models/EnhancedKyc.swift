import Foundation

public struct EnhancedKycRequest: Codable {
    public let country: String
    public let idType: String
    public let idNumber: String
    public let firstName: String?
    public let middleName: String?
    public let lastName: String?
    public let dob: String?
    public let phoneNumber: String?
    public let bankCode: String?
    public let callbackUrl: String?
    public let partnerParams: PartnerParams
    public let timestamp: String
    public let signature: String
    public let partnerId: String = SmileID.config.partnerId
    public let sourceSdk: String = "ios"
    public let sourceSdkVersion = SmileID.version
    
    public init(
        country: String,
        idType: String,
        idNumber: String,
        firstName: String? = nil,
        middleName: String? = nil,
        lastName: String? = nil,
        dob: String? = nil,
        phoneNumber: String? = nil,
        bankCode: String? = nil,
        callbackUrl: String?,
        partnerParams: PartnerParams,
        timestamp: String,
        signature: String
    ) {
        self.country = country
        self.idType = idType
        self.idNumber = idNumber
        self.firstName = firstName
        self.middleName = middleName
        self.lastName = lastName
        self.dob = dob
        self.phoneNumber = phoneNumber
        self.bankCode = bankCode
        self.callbackUrl = callbackUrl
        self.partnerParams = partnerParams
        self.timestamp = timestamp
        self.signature = signature
    }

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
