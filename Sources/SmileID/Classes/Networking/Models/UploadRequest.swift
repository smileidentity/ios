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
        case country = "country"
        case idType = "id_type"
        case idNumber = "id_number"
        case firstName = "first_name"
        case middleName = "middle_name"
        case lastName = "last_name"
        case dob = "dob"
        case bankCode = "bank_code"
        case entered = "entered"
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
