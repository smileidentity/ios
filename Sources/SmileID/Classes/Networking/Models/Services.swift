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
    let name, code: String
}

// MARK: - HostedWeb

public struct HostedWeb: Codable {
    let basicKyc: CountryCodeToCountryInfo
    let biometricKyc: CountryCodeToCountryInfo
    let enhancedKyc: CountryCodeToCountryInfo
    let docVerification: CountryCodeToCountryInfo
    let enhancedKycSmartSelfie: CountryCodeToCountryInfo

    private enum CodingKeys: String, CodingKey {
        case basicKyc = "basic_kyc"
        case biometricKyc = "biometric_kyc"
        case enhancedKyc = "enhanced_kyc"
        case docVerification = "doc_verification"
        case enhancedKycSmartSelfie = "ekyc_smartselfie"
    }
}

// MARK: - CountryInfo

public struct CountryInfo: Codable {
    let countryCode: String
    let name: String
    let availableIdTypes: [AvailableIdType]

    private enum CodingKeys: String, CodingKey {
        case countryCode
        case name
        case availableIdTypes = "id_types"
    }
}

// MARK: - AvailableIdType

public struct AvailableIdType: Codable {
    let idTypeKey: String
    let label: String
    let requiredFields: [RequiredField]
    let testData: String?
    let idNumberRegex: String?

    private enum CodingKeys: String, CodingKey {
        case idTypeKey
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
    case unknown = "Unknown"

    private enum CodingKeys: String, CodingKey {
        case idNumber = "id_number"
        // map other cases to JSON keys
    }
}

// MARK: - CountryCodeToCountryInfo

public typealias CountryCodeToCountryInfo = [String: CountryInfo]

// MARK: - IdTypeKeyToAvailableIdType

public typealias IdTypeKeyToAvailableIdType = [String: AvailableIdType]
