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

/**
 * Class representing user consent information submitted with verification jobs.
 * As of version 10.6.2, the structure was updated to match API requirements by nesting
 * consent fields under a "consented" object. This class provides backward compatibility
 * with previous SDK versions while maintaining the new API-compatible JSON structure.
 *
 * Preferred usage (current API format):
 * ```
 * let consentInfo = ConsentInformation(
 *     consented: ConsentedInformation(
 *         consentGrantedDate: getCurrentIsoTimestamp(),
 *         personalDetails: true,
 *         contactInformation: true,
 *         documentInformation: true
 *     )
 * )
 * ```
 *
 * For backward compatibility, you can also use the secondary convenience initializer with the old property names:
 * ```
 * // Direct construction with legacy property names (will be converted to the new structure internally)
 * let consentInfo = ConsentInformation(
 *     consentGrantedDate: getCurrentIsoTimestamp(),
 *     personalDetailsConsentGranted: true,
 *     contactInfoConsentGranted: true,
 *     documentInfoConsentGranted: true
 * )
 * ```
 *
 * Or the legacy factory method:
 * ```
 * // Legacy factory method (will be converted to the new structure internally)
 * let consentInfo = ConsentInformation.createLegacy(
 *     consentGrantedDate: getCurrentIsoTimestamp(),
 *     personalDetailsConsentGranted: true,
 *     contactInfoConsentGranted: true,
 *     documentInfoConsentGranted: true
 * )
 * ```
 *
 * All three approaches will produce identical API-compatible JSON output with the nested structure.
 *
 * @property consented The nested consent information object containing all consent fields
 */
public struct ConsentInformation: Codable {
    public let consented: ConsentedInformation

    /**
     * Primary initializer that uses the new nested structure required by the API.
     *
     * @param consented The nested consent information object
     */
    public init(consented: ConsentedInformation) {
        self.consented = consented
    }

    /**
     * Convenience initializer to support direct creation with legacy properties.
     * This initializer creates the object with the new nested structure
     * but accepts parameters in the old format for backward compatibility.
     *
     * @param consentGrantedDate The timestamp of when consent was granted
     * @param personalDetailsConsentGranted Whether consent for personal details was granted
     * @param contactInfoConsentGranted Whether consent for contact information was granted
     * @param documentInfoConsentGranted Whether consent for document information was granted
     */
    @available(*, deprecated, message: "Use primary initializer with ConsentedInformation instead")
    public init(
        consentGrantedDate: String = Date().toISO8601WithMilliseconds(),
        personalDetailsConsentGranted: Bool = false,
        contactInfoConsentGranted: Bool = false,
        documentInfoConsentGranted: Bool = false
    ) {
        self.consented = ConsentedInformation(
            consentGrantedDate: consentGrantedDate,
            personalDetails: personalDetailsConsentGranted,
            contactInformation: contactInfoConsentGranted,
            documentInformation: documentInfoConsentGranted
        )
    }

    enum CodingKeys: String, CodingKey {
        case consented
    }

    // Backward compatibility with previous versions - computed properties that
    // map to the nested structure

    /**
     * Access the consent granted date from the nested structure.
     *
     * @return The consent granted date
     */
    @available(*, deprecated, message: "Use consented.consentGrantedDate instead")
    public var consentGrantedDate: String {
        return consented.consentGrantedDate
    }

    /**
     * Access whether consent for personal details was granted from the nested structure.
     *
     * @return Whether consent for personal details was granted
     */
    @available(*, deprecated, message: "Use consented.personalDetails instead")
    public var personalDetailsConsentGranted: Bool {
        return consented.personalDetails
    }

    /**
     * Access whether consent for contact information was granted from the nested structure.
     *
     * @return Whether consent for contact information was granted
     */
    @available(*, deprecated, message: "Use consented.contactInformation instead")
    public var contactInfoConsentGranted: Bool {
        return consented.contactInformation
    }

    /**
     * Access whether consent for document information was granted from the nested structure.
     *
     * @return Whether consent for document information was granted
     */
    @available(*, deprecated, message: "Use consented.documentInformation instead")
    public var documentInfoConsentGranted: Bool {
        return consented.documentInformation
    }

    /**
     * Contains factory methods for backward compatibility with older SDK versions.
     */
    public static func createLegacy(
        consentGrantedDate: String = Date().toISO8601WithMilliseconds(),
        personalDetailsConsentGranted: Bool = false,
        contactInfoConsentGranted: Bool = false,
        documentInfoConsentGranted: Bool = false
    ) -> ConsentInformation {
        return ConsentInformation(
            consented: ConsentedInformation(
                consentGrantedDate: consentGrantedDate,
                personalDetails: personalDetailsConsentGranted,
                contactInformation: contactInfoConsentGranted,
                documentInformation: documentInfoConsentGranted
            )
        )
    }
}

/**
 * Represents the detailed consent information nested within [ConsentInformation].
 * This class follows the API's expected structure for consent data.
 *
 * @property consentGrantedDate The ISO timestamp of when consent was granted
 * @property personalDetails Whether consent for personal details was granted
 * @property contactInformation Whether consent for contact information was granted
 * @property documentInformation Whether consent for document information was granted
 */
public struct ConsentedInformation: Codable {
    public let consentGrantedDate: String
    public let personalDetails: Bool
    public let contactInformation: Bool
    public let documentInformation: Bool

    public init(
        consentGrantedDate: String = Date().toISO8601WithMilliseconds(),
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
