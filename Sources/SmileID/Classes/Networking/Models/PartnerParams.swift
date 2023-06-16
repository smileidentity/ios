import Foundation

public struct PartnerParams: Codable {
    public var jobId: String
    public var userId: String
    public var jobType: JobType

    enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
        case userId = "user_id"
        case jobType = "job_type"
    }
}
