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

    var unpackedExtras: [String: String] {
        var unpacked = [String: String]()
        unpacked[CodingKeys.jobId.rawValue] = jobId
        unpacked[CodingKeys.userId.rawValue] = userId
        if let jobType = jobType {
            unpacked[CodingKeys.jobType.rawValue] = String(jobType.rawValue)
        }
        if let extras = extras {
            for (key, value) in extras {
                unpacked[key] = value
            }
        }
        return unpacked
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(self.unpackedExtras)
    }

}
