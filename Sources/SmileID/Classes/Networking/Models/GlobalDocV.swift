import Foundation

public struct GlobalDocVResponse: Codable {
    public let validDocuments: [ValidDocument]

    public init(validDocuments: [ValidDocument]) {
        self.validDocuments = validDocuments
    }

    enum CodingKeys: String, CodingKey {
        case validDocuments = "valid_documents"
    }
}

public struct ValidDocument: Codable {
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

public struct IdType: Codable {
    public let code: String
    public let example: [String]
    public let hasBack: Bool
    public let name: String


    public init(code: String,
                example: [String],
                hasBack: Bool,
                name: String) {
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
