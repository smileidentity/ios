import Foundation

public struct SelfieRequest: Codable {
    public var selfieImage: Data
    public var livenessImages: [Data]
    public var userId: String?
    public var partnerParams: [String: String]?
    public var callbackUrl: String?
    public var sandboxResult: Int?
    public var allowNewEnroll: Bool?
    public var failureReason: FailureReason?
    public var metadata: [Metadatum]

    public init(
        selfieImage: Data,
        livenessImages: [Data],
        userId: String? = nil,
        partnerParams: [String: String]? = nil,
        callbackUrl: String? = nil,
        sandboxResult: Int? = nil,
        allowNewEnroll: Bool? = nil,
        failureReason: FailureReason? = nil,
        metadata: [Metadatum]
    ) {
        self.selfieImage = selfieImage
        self.livenessImages = livenessImages
        self.userId = userId
        self.partnerParams = partnerParams
        self.callbackUrl = callbackUrl
        self.sandboxResult = sandboxResult
        self.allowNewEnroll = allowNewEnroll
        self.failureReason = failureReason
        self.metadata = metadata
    }

    enum CodingKeys: String, CodingKey {
        case selfieImage = "selfie_image"
        case livenessImages = "liveness_images"
        case userId = "user_id"
        case partnerParams = "partner_params"
        case callbackUrl = "callback_url"
        case sandboxResult = "sandbox_result"
        case allowNewEnroll = "allow_new_enroll"
        case failureReason = "failure_reason"
        case metadata
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(selfieImage.base64EncodedString(), forKey: .selfieImage)
        try container.encode(livenessImages.map { $0.base64EncodedString() }, forKey: .livenessImages)
        if let userId = userId {
            try container.encode(userId, forKey: .userId)
        }
        try container.encode(partnerParams, forKey: .partnerParams)
        if let callbackUrl = callbackUrl {
            try container.encode(callbackUrl, forKey: .callbackUrl)
        }
        if let sandboxResult = sandboxResult {
            try container.encode(sandboxResult, forKey: .sandboxResult)
        }
        if let allowNewEnroll = allowNewEnroll {
            try container.encode(allowNewEnroll, forKey: .allowNewEnroll)
        }
        if let failureReason = failureReason {
            try container.encode(failureReason, forKey: .failureReason)
        }
        try container.encode(metadata, forKey: .metadata)
    }
}
