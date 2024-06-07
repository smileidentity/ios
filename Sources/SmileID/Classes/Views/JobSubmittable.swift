import Combine
import Foundation

protocol JobSubmittable {
    func getJobStatus<T: JobResult>(
        _ authResponse: AuthenticationResponse
    ) async throws -> JobStatusResponse<T>
    func upload(
        _ prepUploadResponse: PrepUploadResponse, zip: Data
    ) async throws -> UploadResponse
    func prepUpload(
        authResponse: AuthenticationResponse,
        allowNewEnroll: Bool,
        extraPartnerParams: [String: String]
    ) async throws -> PrepUploadResponse
    func handleRetry()
    func handleClose()
}

extension JobSubmittable {
    func prepUpload(
        authResponse: AuthenticationResponse,
        allowNewEnroll: Bool,
        extraPartnerParams: [String: String]
    ) async throws -> PrepUploadResponse {
        let prepUploadRequest = PrepUploadRequest(
            partnerParams: authResponse.partnerParams.copy(extras: extraPartnerParams),
            allowNewEnroll: String(allowNewEnroll), // TODO - Fix when Michael changes this to boolean
            timestamp: authResponse.timestamp,
            signature: authResponse.signature
        )
        return try await SmileID.api.prepUpload(request: prepUploadRequest)
    }

    func upload(
        _ prepUploadResponse: PrepUploadResponse,
        zip: Data
    ) async throws -> UploadResponse {
        try await SmileID.api.upload(zip: zip, to: prepUploadResponse.uploadUrl)
    }

    func getJobStatus<T: JobResult>(
        _ authResponse: AuthenticationResponse
    ) async throws -> JobStatusResponse<T> {
        let jobStatusRequest = JobStatusRequest(
            userId: authResponse.partnerParams.userId,
            jobId: authResponse.partnerParams.jobId,
            includeImageLinks: false,
            includeHistory: false,
            timestamp: authResponse.timestamp,
            signature: authResponse.signature
        )
        return try await SmileID.api.getJobStatus(request: jobStatusRequest)
    }
}
