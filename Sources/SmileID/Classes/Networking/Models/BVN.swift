import Foundation
private let nigeriaCountryCode = "NG"
private let bvnIdType = "BVN_MFA"

public struct BvnTotpRequest: Codable {
    public var idNumber: String
    public var timestamp: String = Date().toISO8601WithMilliseconds()
    public var signature: String
    public var country: String = nigeriaCountryCode
    public var idType: String = bvnIdType
    public var partnerId: String = SmileID.config.partnerId

    enum CodingKeys: String, CodingKey {
        case country = "country"
        case idNumber = "id_number"
        case idType = "id_type"
        case partnerId = "partner_id"
        case timestamp = "timestamp"
        case signature = "signature"
    }
}

public typealias BvnVerificationMode = [String: String]

public struct BvnTotpResponse: Codable {
    public let success: Bool
    public let message: String
    public let modes: [BvnVerificationMode]
    public let sessionId: String
    public let timestamp: String
    public let signature: String

    enum CodingKeys: String, CodingKey {
        case success = "success"
        case message = "message"
        case modes = "modes"
        case sessionId = "session_id"
        case timestamp = "timestamp"
        case signature = "signature"
    }
}

public struct BvnTotpModeRequest: Codable {
    public var idNumber: String
    public var mode: String
    public var sessionId: String
    public var timestamp: String = Date().toISO8601WithMilliseconds()
    public var signature: String
    public var country: String = nigeriaCountryCode
    public var idType: String = bvnIdType
    public var partnerId: String = SmileID.config.partnerId

    enum CodingKeys: String, CodingKey {
        case idNumber = "id_number"
        case mode = "mode"
        case sessionId = "session_id"
        case timestamp = "timestamp"
        case signature = "signature"
        case country = "country"
        case idType = "id_type"
        case partnerId = "partner_id"
    }
}

public struct BvnTotpModeResponse: Codable {
    public let success: Bool
    public let message: String
    public let timestamp: String
    public let signature: String

    enum CodingKeys: String, CodingKey {
        case success = "success"
        case message = "message"
        case timestamp = "timestamp"
        case signature = "signature"
    }
}

public struct SubmitBvnTotpRequest: Codable {
    public var idNumber: String
    public var otp: String
    public var sessionId: String
    public var country: String = nigeriaCountryCode
    public var idType: String = bvnIdType
    public var partnerId: String = SmileID.config.partnerId
    public var timestamp: String = Date().toISO8601WithMilliseconds()
    public var signature: String

    enum CodingKeys: String, CodingKey {
        case idNumber = "id_number"
        case otp = "otp"
        case sessionId = "session_id"
        case country = "country"
        case idType = "id_type"
        case partnerId = "partner_id"
        case timestamp = "timestamp"
        case signature = "signature"
    }
}

public struct SubmitBvnTotpResponse: Codable {
    public let success: Bool
    public let message: String
    public let timestamp: String
    public let signature: String

    enum CodingKeys: String, CodingKey {
        case success = "success"
        case message = "message"
        case timestamp = "timestamp"
        case signature = "signature"
    }
}
