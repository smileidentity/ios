import Foundation

public struct PartnerParams: Codable {
    public var jobId: String
    public var userId: String
    public var jobType: JobType

    public init(jobId: String,
                userId: String,
                jobType: JobType) {
        self.jobId = jobId
        self.userId = userId
        self.jobType = jobType
    }

    enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
        case userId = "user_id"
        case jobType = "job_type"
    }
}
