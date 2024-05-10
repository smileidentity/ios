import Foundation

public struct PartnerParams: Codable {
    public var jobId: String
    public var userId: String
    public var jobType: JobType?
    public var extras: [String: String]?

    public init(
        jobId: String,
        userId: String,
        jobType: JobType?,
        extras: [String: String]?
    ) {
        self.jobId = jobId
        self.userId = userId
        self.jobType = jobType
        self.extras = extras
    }

    enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
        case userId = "user_id"
        case jobType = "job_type"
        case extras
    }

    // Method for copying with modified properties
    func copy(extras: [String: String]?) -> PartnerParams {
        PartnerParams(
            jobId: jobId, userId: userId, jobType: jobType, extras: extras
        )
    }
}
// made this seperate in case we need to do this for any
// other class in future
extension PartnerParams {
    struct DynamicCodingKey: CodingKey {
        var stringValue: String
        var intValue: Int?

        init?(stringValue: String) {
            self.stringValue = stringValue
            intValue = nil
        }

        // not used but required by CodingKey
        init?(intValue: Int) {
            stringValue = String(intValue)
            self.intValue = intValue
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)

        // Encode known properties with predefined keys
        try container.encode(jobId, forKey: .init(stringValue: CodingKeys.jobId.rawValue)!)
        try container.encode(userId, forKey: .init(stringValue: CodingKeys.userId.rawValue)!)
        if let jobType = jobType {
            try container.encode(jobType, forKey: .init(stringValue: CodingKeys.jobType.rawValue)!)
        }

        // Encode extras directly at the root level
        if let extras = extras {
            for (key, value) in extras {
                if key != "job_id" && key != "user_id" && key != "job_type" {
                    try container.encode(value, forKey: .init(stringValue: key)!)
                }
            }
        }
    }
}
