import Foundation

public struct UploadRequest: Codable {
    public var images: [UploadImageInfo]
    public var idInfo: IdInfo?
    public var consentInformation: ConsentInformation?

    public init(
        images: [UploadImageInfo],
        idInfo: IdInfo? = nil,
        consentInformation: ConsentInformation? = nil
    ) {
        self.images = images
        self.idInfo = idInfo
        self.consentInformation = consentInformation
    }

    enum CodingKeys: String, CodingKey {
        case images
        case idInfo = "id_info"
        case consentInformation = "consent_information"
    }
}

public struct IdInfo: Codable {
    public let country: String
    public let idType: String?
    public let idNumber: String?
    public let firstName: String?
    public let middleName: String?
    public let lastName: String?
    public let dob: String?
    public let bankCode: String?
    public let entered: Bool?

    public init(
        country: String,
        idType: String? = nil,
        idNumber: String? = nil,
        firstName: String? = nil,
        middleName: String? = nil,
        lastName: String? = nil,
        dob: String? = nil,
        bankCode: String? = nil,
        entered: Bool? = nil
    ) {
        self.country = country
        self.idType = idType
        self.idNumber = idNumber
        self.firstName = firstName
        self.middleName = middleName
        self.lastName = lastName
        self.dob = dob
        self.bankCode = bankCode
        self.entered = entered
    }

    enum CodingKeys: String, CodingKey {
        case country
        case idType = "id_type"
        case idNumber = "id_number"
        case firstName = "first_name"
        case middleName = "middle_name"
        case lastName = "last_name"
        case dob
        case bankCode = "bank_code"
        case entered
    }

    // Method for copying with modified properties
    func copy(entered: Bool?) -> IdInfo {
        IdInfo(
            country: country,
            idType: idType,
            idNumber: idNumber,
            firstName: firstName,
            middleName: middleName,
            lastName: lastName,
            dob: dob,
            bankCode: bankCode,
            entered: entered
        )
    }
}

public struct ConsentInformation: Codable {
    public let consented: ConsentedInformation
    // Legacy properties for backward compatibility
    private var personalDetailsConsentGranted: Bool?
    private var contactInformationConsentGranted: Bool?
    private var documentInformationConsentGranted: Bool?
    private var consentDate: String?

    // Current initializer marked with @available to indicate it's the preferred method
    @available(*, message: "Preferred initializer for ConsentInformation")
    public init(
        consentGrantedDate: String,
        personalDetails: Bool,
        contactInformation: Bool,
        documentInformation: Bool
    ) {
        self.consented = ConsentedInformation(
            consentGrantedDate: consentGrantedDate,
            personalDetails: personalDetails,
            contactInformation: contactInformation,
            documentInformation: documentInformation
        )
    }

    // Legacy initializer marked as deprecated
    @available(
        *,
        deprecated,
        message: "Use init(consentGrantedDate:personalDetails:contactInformation:documentInformation:) instead"
    )
    public init(
        personalDetailsConsentGranted: Bool,
        contactInformationConsentGranted: Bool,
        documentInformationConsentGranted: Bool,
        consentDate: String
    ) {
        self.consented = ConsentedInformation(
            consentGrantedDate: consentDate,
            personalDetails: personalDetailsConsentGranted,
            contactInformation: contactInformationConsentGranted,
            documentInformation: documentInformationConsentGranted
        )

        // Store in legacy properties for potential future use
        self.personalDetailsConsentGranted = personalDetailsConsentGranted
        self.contactInformationConsentGranted = contactInformationConsentGranted
        self.documentInformationConsentGranted = documentInformationConsentGranted
        self.consentDate = consentDate
    }

    enum CodingKeys: String, CodingKey {
        case consented
    }
}

public struct ConsentedInformation: Codable {
    public let consentGrantedDate: String
    public let personalDetails: Bool
    public let contactInformation: Bool
    public let documentInformation: Bool

    public init(
        consentGrantedDate: String,
        personalDetails: Bool,
        contactInformation: Bool,
        documentInformation: Bool
    ) {
        self.consentGrantedDate = consentGrantedDate
        self.personalDetails = personalDetails
        self.contactInformation = contactInformation
        self.documentInformation = documentInformation
    }

    enum CodingKeys: String, CodingKey {
        case consentGrantedDate = "consent_granted_date"
        case personalDetails = "personal_details"
        case contactInformation = "contact_information"
        case documentInformation = "document_information"
    }
}

public struct UploadImageInfo: Codable {
    public var imageTypeId: ImageType
    public var fileName: String

    public init(
        imageTypeId: ImageType,
        fileName: String
    ) {
        self.imageTypeId = imageTypeId
        self.fileName = fileName
    }

    enum CodingKeys: String, CodingKey {
        case imageTypeId = "image_type_id"
        case fileName = "file_name"
    }
}

public enum ImageType: String, Codable {
    case selfieJpgFile = "0"
    case idCardJpgFile = "1"
    case selfieJpgBase64 = "2"
    case idCardJpgBase64 = "3"
    case livenessJpgFile = "4"
    case idCardRearJpgFile = "5"
    case livenessJpgBase64 = "6"
    case idCardRearJpgBase64 = "7"
}
