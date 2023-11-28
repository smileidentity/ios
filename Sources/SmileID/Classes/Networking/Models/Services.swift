import Foundation

// MARK: - ServicesResponse

public struct ServicesResponse: Codable {
    public let bankCodes: [BankCode]
    public let hostedWeb: HostedWeb

    enum CodingKeys: String, CodingKey {
        case bankCodes = "bank_codes"
        case hostedWeb = "hosted_web"
    }
}

// MARK: - BankCode

public struct BankCode: Codable {
    public let name, code: String
}

// MARK: - HostedWeb

public struct HostedWeb: Codable {
    public let basicKyc: [CountryInfo]
    public let biometricKyc: [CountryInfo]
    public let enhancedKyc: [CountryInfo]
    public let docVerification: [CountryInfo]
    public let enhancedDocumentVerification: [CountryInfo]
    public let enhancedKycSmartSelfie: [CountryInfo]

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        basicKyc = try container.decode(
            CountryCodeToCountryInfo.self,
            forKey: .basicKyc
        ).toCountryInfo()
        biometricKyc = try container.decode(
            CountryCodeToCountryInfo.self,
            forKey: .biometricKyc
        ).toCountryInfo()
        enhancedKyc = try container.decode(
            CountryCodeToCountryInfo.self,
            forKey: .enhancedKyc
        ).toCountryInfo()
        docVerification = try container.decode(
            CountryCodeToCountryInfo.self,
            forKey: .docVerification
        ).toCountryInfo()
        enhancedDocumentVerification = try container.decode(
            CountryCodeToCountryInfo.self,
            forKey: .enhancedDocumentVerification
        ).toCountryInfo()
        enhancedKycSmartSelfie = try container.decode(
            CountryCodeToCountryInfo.self,
            forKey: .enhancedKycSmartSelfie
        ).toCountryInfo()
    }

    private enum CodingKeys: String, CodingKey {
        case basicKyc = "basic_kyc"
        case biometricKyc = "biometric_kyc"
        case enhancedKyc = "enhanced_kyc"
        case docVerification = "doc_verification"
        case enhancedDocumentVerification = "enhanced_document_verification"
        case enhancedKycSmartSelfie = "ekyc_smartselfie"
    }
}

// MARK: - CountryInfo
/**
 * The countryCode field is not populated/returned by the API response, hence it being marked as
 * mutable. However, it should be populated before usage of this class/when the response gets decoded.
 * The same applies to availableIdTypes
 */
public struct CountryInfo: Codable, Identifiable {
    public var countryCode = ""
    public let name: String
    public let availableIdTypes: [AvailableIdType]

    public var id: String { countryCode }

    private enum CodingKeys: String, CodingKey {
        case name
        case availableIdTypes = "id_types"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        availableIdTypes = try container.decode(
            IdTypeKeyToAvailableIdType.self,
            forKey: .availableIdTypes
        ).toAvailableIdTypes()
    }
}

// MARK: - AvailableIdType
/**
 * The  idTypeKey field is not populated/returned by the API response, hence it being marked as
 * mutable. However, it should be populated before usage of this class/when the response gets decoded
 */
public struct AvailableIdType: Codable, Identifiable, Equatable {
    public var idTypeKey = ""
    public let label: String
    public let requiredFields: [RequiredField]?
    public let testData: String?
    public let idNumberRegex: String?

    public var id: String { idTypeKey }

    private enum CodingKeys: String, CodingKey {
        case label
        case requiredFields = "required_fields"
        case testData = "test_data"
        case idNumberRegex = "id_number_regex"
    }
}

// MARK: - RequiredField

public enum RequiredField: String, Codable {
    case idNumber = "id_number"
    case firstName = "first_name"
    case lastName = "last_name"
    case dateOfBirth = "dob"
    case day
    case month
    case year
    case bankCode = "bank_code"
    case citizenship
    case country
    case idType = "id_type"
    case userId = "user_id"
    case jobId = "job_id"

    // To allow displaying inputs in some logical+consistent order
    private static let sortedCases: [RequiredField] = [
        .idNumber,
        .firstName,
        .lastName,
        .dateOfBirth,
        .day,
        .month,
        .year,
        .bankCode,
        .citizenship,
        .country,
        .idType,
        .userId,
        .jobId
    ]

    public static func sorter(this: RequiredField, that: RequiredField) -> Bool {
        let thisIndex = sortedCases.firstIndex(of: this) ?? 0
        let thatIndex = sortedCases.firstIndex(of: that) ?? 0
        return thisIndex < thatIndex
    }
}

// MARK: - CountryCodeToCountryInfo

public typealias CountryCodeToCountryInfo = [String: CountryInfo]

// MARK: - IdTypeKeyToAvailableIdType

public typealias IdTypeKeyToAvailableIdType = [String: AvailableIdType]

extension CountryCodeToCountryInfo {
    func toCountryInfo() -> [CountryInfo] {
        self.map { key, value in
            var countryInfo = value
            countryInfo.countryCode = key
            return countryInfo
        }
    }
}

extension IdTypeKeyToAvailableIdType {
    func toAvailableIdTypes() -> [AvailableIdType] {
        self.map { key, value in
            var availableIdType = value
            availableIdType.idTypeKey = key
            return availableIdType
        }
    }
}
