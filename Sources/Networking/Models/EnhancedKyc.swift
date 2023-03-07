import Foundation

public struct EnhancedKycRequest: Codable {
    var country: String
    var idType: String
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

}

public struct EnhancedKycResponse: Codable {
    var smileJobId: String
    var partnerParams: PartnerParams
    var resultType: String
    var resultCode: String
    var resultText: String
    var country: String
    var actions: Actions
    var idType: String
    var idNumber: String
    var fullName: String?
    var expirationDate: String?
    var dob: String?
    var base64Photo: String?
    var isFinalResult: Bool
}

enum IDType {
    case GhanaDriversLicense(countryCode: String, idType: String, regex: String)
}
