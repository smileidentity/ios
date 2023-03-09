import Foundation

public struct EnhancedKycRequest: Codable {
    var country: String
    var idType: String
    var idNumber: String
    var firstName: String
    var middleName: String
    var lastName: String
    var dob: String
    var phoneNumber: String
    var bankCode: String
    var partnerParams: PartnerParams
    var partnerId = SmileIdentity.config.partnerId
    var sourceSdk = "iOS"
    var sourceSdkVersion = ""
    var timestamp = ""
    var signature = ""

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
        case partnerParams = "partner_params"
        case partnerId = "partner_id"
        case sourceSdk = "source_sdk"
        case sourceSdkVersion = "source_sdk_version"
        case timestamp
        case signature
    }

}

public struct EnhancedKycResponse: Codable {
    var smileJobId: String
    var partnerParams: PartnerParams
    var resultType: String
    var resultCode: String
    var resultText: String
    var country: String
    var actions: Actions?
    var idType: String
    var idNumber: String
    var fullName: String?
    var expirationDate: String?
    var dob: String?
    var base64Photo: String?
    var isFinalResult: Bool

    enum CodingKeys: String, CodingKey {
        case smileJobId = "SmileJobID"
        case partnerParams = "PartnerParams"
        case resultType = "ResultType"
        case resultCode = "ResultCode"
        case resultText = "ResultText"
        case country = "Country"
        case actions = "Actions"
        case idType = "IDType"
        case idNumber = "IDNumber"
        case fullName = "FullName"
        case expirationDate = "ExpirationDate"
        case dob = "DOB"
        case base64Photo = "Photo"
        case isFinalResult = "IsFinalResult"
    }
}

enum IDType {
    case GhanaDriversLicense(countryCode: String, idType: String, regex: String)
}
