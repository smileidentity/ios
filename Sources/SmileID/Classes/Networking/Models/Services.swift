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
    var basicKyc: CountryCodeToCountryInfo
    var biometricKyc: CountryCodeToCountryInfo
    var enhancedKyc: CountryCodeToCountryInfo
    var docVerification: CountryCodeToCountryInfo
    var enhancedKycSmartSelfie: CountryCodeToCountryInfo

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        basicKyc = try container.decode(CountryCodeToCountryInfo.self, forKey: .basicKyc)
        biometricKyc = try container.decode(CountryCodeToCountryInfo.self, forKey: .biometricKyc)
        enhancedKyc = try container.decode(CountryCodeToCountryInfo.self, forKey: .enhancedKyc)
        docVerification = try container.decode(CountryCodeToCountryInfo.self, forKey: .docVerification)
        enhancedKycSmartSelfie = try container.decode(CountryCodeToCountryInfo.self, forKey: .enhancedKycSmartSelfie)

        basicKyc = basicKyc.toCountryInfo()
        biometricKyc = biometricKyc.toCountryInfo()
        enhancedKyc = enhancedKyc.toCountryInfo()
        docVerification = docVerification.toCountryInfo()
        enhancedKycSmartSelfie = enhancedKycSmartSelfie.toCountryInfo()
    }

    private enum CodingKeys: String, CodingKey {
        case basicKyc = "basic_kyc"
        case biometricKyc = "biometric_kyc"
        case enhancedKyc = "enhanced_kyc"
        case docVerification = "doc_verification"
        case enhancedKycSmartSelfie = "ekyc_smartselfie"
    }
}

// MARK: - CountryInfo
/**
 * The countryCode  field is not populated/returned by the API response, hence it being marked as
 * mutable. However, it should be populated before usage of this class.when the response gets decoded
 *the same applies to availableIdTypes
 */
public struct CountryInfo: Codable {
    var countryCode = ""
    let name: String
    var availableIdTypes: IdTypeKeyToAvailableIdType

    private enum CodingKeys: String, CodingKey {
        case name
        case availableIdTypes = "id_types"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        availableIdTypes = try container.decode(IdTypeKeyToAvailableIdType.self, forKey: .availableIdTypes)
        availableIdTypes = availableIdTypes.toAvailableIdTypes()
    }
}

// MARK: - AvailableIdType
/**
 * The  idTypeKey  field is not populated/returned by the API response, hence it being marked as
 * mutable. However, it should be populated before usage of this class.when the response gets decoded
 */
public struct AvailableIdType: Codable {
    var idTypeKey = ""
    let label: String
    let requiredFields: [RequiredField] = []
    let testData: String?
    let idNumberRegex: String?

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
    case unknown = "Unknown"
}

// MARK: - CountryCodeToCountryInfo

public typealias CountryCodeToCountryInfo = [String: CountryInfo]

// MARK: - IdTypeKeyToAvailableIdType

public typealias IdTypeKeyToAvailableIdType = [String: AvailableIdType]

extension CountryCodeToCountryInfo {
    func toCountryInfo() -> CountryCodeToCountryInfo {
        var countryInfo: CountryInfo?
        map { key, value in
            countryInfo = value
            countryInfo?.countryCode = key
        }
        guard let countryInfo else {
            return self
        }
        return Dictionary(uniqueKeysWithValues:
            map { key, _ in (key, countryInfo) })
    }
}

extension IdTypeKeyToAvailableIdType {
    func toAvailableIdTypes() -> IdTypeKeyToAvailableIdType {
        var availableIdType: AvailableIdType?
        map { key, value in
            availableIdType = value
            availableIdType?.idTypeKey = key
        }
        guard let availableIdType else {
            return self
        }
        return Dictionary(uniqueKeysWithValues:
            map { key, _ in (key, availableIdType) })
    }
}
