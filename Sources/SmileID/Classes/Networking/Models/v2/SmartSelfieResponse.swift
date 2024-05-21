import Foundation

public struct SmartSelfieResponse: Codable {
    public let code: String
    public let createdAt: String
    public let jobId: String
    public let jobType: JobTypeV2
    public let message: String
    public let partnerId: String
    public let partnerParams: [String: String]
    public let status: SmartSelfieStatus
    public let updatedAt: String
    public let userId: String

    enum CodingKeys: String, CodingKey {
            case code
            case createdAt = "created_at"
            case jobId = "job_id"
            case jobType = "job_type"
            case message
            case partnerId = "partner_id"
            case partnerParams = "partner_params"
            case status
            case updatedAt = "updated_at"
            case userId = "user_id"
        }
}
