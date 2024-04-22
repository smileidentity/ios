import Foundation

public struct SmartSelfieResponse: Codable {
    let code: String
    let createdAt: String
    let jobId: String
    let jobType: JobTypeV2
    let message: String
    let partnerId: String
    let partnerParams: [String: String]
    let status: SmartSelfieStatus
    let updatedAt: String
    let userId: String
}
