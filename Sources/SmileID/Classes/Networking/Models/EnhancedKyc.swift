import Foundation

public struct EnhancedKycRequest: Codable {
    public let country: String
    public let idType: String
    public let idNumber: String
    public let consentInformation: ConsentInformation
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
    public let sourceSdk: String
    public let sourceSdkVersion: String
    private var metadata: [Metadatum]?

    public init(
        country: String,
        idType: String,
        idNumber: String,
        consentInformation: ConsentInformation = ConsentInformation(
            consented: ConsentedInformation(consentGrantedDate: Date().toISO8601WithMilliseconds(),
                                            personalDetails: false,
                                            contactInformation: false,
                                            documentInformation: false)
        ),
        firstName: String? = nil,
        middleName: String? = nil,
        lastName: String? = nil,
        dob: String? = nil,
        phoneNumber: String? = nil,
        bankCode: String? = nil,
        callbackUrl: String? = SmileID.callbackUrl,
        partnerParams: PartnerParams,
        sourceSdk: String = "ios",
        sourceSdkVersion: String = SmileID.version,
        timestamp: String,
        signature: String
    ) {
        self.country = country
        self.idType = idType
        self.idNumber = idNumber
        self.consentInformation = consentInformation
        self.firstName = firstName
        self.middleName = middleName
        self.lastName = lastName
        self.dob = dob
        self.phoneNumber = phoneNumber
        self.bankCode = bankCode
        self.callbackUrl = callbackUrl
        self.partnerParams = partnerParams
        self.sourceSdk = sourceSdk
        self.sourceSdkVersion = sourceSdkVersion
        self.timestamp = timestamp
        self.signature = signature
        Metadata.shared.initialize()
        self.metadata = Metadata.shared.collectAllMetadata()
    }

    enum CodingKeys: String, CodingKey {
        case country
        case idType = "id_type"
        case idNumber = "id_number"
        case consentInformation = "consent_information"
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
        case metadata
    }
}

public struct EnhancedKycResponse: Codable {
    public let smileJobId: String
    public let partnerParams: PartnerParams
    public let resultText: String
    public let resultCode: String
    public let actions: Actions
    public let country: String
    public let idType: String
    public let idNumber: String
    public let fullName: String?
    public let expirationDate: String?
    public let dob: String?
    public let photo: String?

    init(
        smileJobId: String,
        partnerParams: PartnerParams,
        resultText: String,
        resultCode: String,
        country: String,
        actions: Actions,
        idType: String,
        idNumber: String,
        fullName: String? = nil,
        expirationDate: String? = nil,
        dob: String? = nil,
        photo: String? = nil
    ) {
        self.smileJobId = smileJobId
        self.partnerParams = partnerParams
        self.resultText = resultText
        self.resultCode = resultCode
        self.country = country
        self.actions = actions
        self.idType = idType
        self.idNumber = idNumber
        self.fullName = fullName
        self.expirationDate = expirationDate
        self.dob = dob
        self.photo = photo
    }

    enum CodingKeys: String, CodingKey {
        case smileJobId = "SmileJobID"
        case partnerParams = "PartnerParams"
        case resultText = "ResultText"
        case resultCode = "ResultCode"
        case actions = "Actions"
        case country = "Country"
        case idType = "IDType"
        case idNumber = "IDNumber"
        case fullName = "FullName"
        case expirationDate = "ExpirationDate"
        case dob = "DOB"
        case photo = "Photo"
    }
}

public struct EnhancedKycAsyncResponse: Codable {
    public var success: Bool

    public init(success: Bool) {
        self.success = success
    }
}
