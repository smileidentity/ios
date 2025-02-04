import Foundation

public struct ValidDocumentsResponse: Codable {
    public let validDocuments: [ValidDocument]

    public init(validDocuments: [ValidDocument]) {
        self.validDocuments = validDocuments
    }

    enum CodingKeys: String, CodingKey {
        case validDocuments = "valid_documents"
    }
}

public struct ValidDocument: Codable, Identifiable {
    public let id = UUID()
    public let country: Country
    public let idTypes: [IdType]

    public init(country: Country, idTypes: [IdType]) {
        self.country = country
        self.idTypes = idTypes
    }

    enum CodingKeys: String, CodingKey {
        case country
        case idTypes = "id_types"
    }
}

public struct Country: Codable {
    public let code: String
    public let continent: String
    public let name: String

    public init(code: String, continent: String, name: String) {
        self.code = code
        self.continent = continent
        self.name = name
    }
}

public struct IdType: Codable, Identifiable, Equatable {
    public let code: String
    public let example: [String]
    public let hasBack: Bool
    public let name: String

    public var id: String { code + name }

    public init(
        code: String,
        example: [String],
        hasBack: Bool,
        name: String
    ) {
        self.code = code
        self.example = example
        self.hasBack = hasBack
        self.name = name
    }

    enum CodingKeys: String, CodingKey {
        case code
        case example
        case hasBack = "has_back"
        case name
    }
}

public struct ProductsConfigRequest: Encodable {
    public let partnerId: String
    public let timestamp: String
    public let signature: String?

    public init() {
        partnerId = SmileID.config.partnerId
        timestamp = Date().toISO8601WithMilliseconds()
        signature = try? calculateSignature(timestamp: timestamp)
    }

    public init(
        timestamp: String,
        signature: String,
        partnerId: String = SmileID.config.partnerId
    ) {
        self.signature = signature
        self.timestamp = timestamp
        self.partnerId = partnerId
    }

    enum CodingKeys: String, CodingKey {
        case partnerId = "partner_id"
        case timestamp
        case signature
    }
}

/// Country Code to ID Type (e.g. {"ZA": ["NATIONAL_ID_NO_PHOTO"]}
public typealias IdTypes = [String: [String]]
public struct ProductsConfigResponse: Codable {
    public let consentRequired: IdTypes
    public let idSelection: IdSelection

    enum CodingKeys: String, CodingKey {
        case consentRequired
        case idSelection
    }
}

public struct IdSelection: Codable {
    public let basicKyc: IdTypes
    public let biometricKyc: IdTypes
    public let enhancedKyc: IdTypes
    public let documentVerification: IdTypes

    enum CodingKeys: String, CodingKey {
        case basicKyc = "basic_kyc"
        case biometricKyc = "biometric_kyc"
        case enhancedKyc = "enhanced_kyc"
        case documentVerification = "doc_verification"
    }
}
