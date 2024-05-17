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
}
