import Combine
import Foundation

protocol JobSubmittable {
    func getJobStatus<T: JobResult>(
        _ authResponse: AuthenticationResponse
    ) -> AnyPublisher<JobStatusResponse<T>, Error>
    func upload(
        _ prepUploadResponse: PrepUploadResponse, zip: Data
    ) -> AnyPublisher<UploadResponse, Error>
    func prepUpload(
        _ authResponse: AuthenticationResponse
    ) -> AnyPublisher<PrepUploadResponse, Error>
    func handleRetry()
    func handleClose()
}

extension JobSubmittable {
    func prepUpload(
        _ authResponse: AuthenticationResponse
    ) -> AnyPublisher<PrepUploadResponse, Error> {
        let prepUploadRequest = PrepUploadRequest(
            partnerParams: authResponse.partnerParams,
            timestamp: authResponse.timestamp,
            signature: authResponse.signature
        )
        return SmileID.api.prepUpload(request: prepUploadRequest)
    }

    func upload(
        _ prepUploadResponse: PrepUploadResponse,
        zip: Data
    ) -> AnyPublisher<UploadResponse, Error> {
        SmileID.api.upload(zip: zip, to: prepUploadResponse.uploadUrl)
            .eraseToAnyPublisher()
    }

    func getJobStatus<T: JobResult>(
        _ authResponse: AuthenticationResponse
    ) -> AnyPublisher<JobStatusResponse<T>, Error> {
        let jobStatusRequest = JobStatusRequest(
            userId: authResponse.partnerParams.userId,
            jobId: authResponse.partnerParams.jobId,
            includeImageLinks: false,
            includeHistory: false,
            timestamp: authResponse.timestamp,
            signature: authResponse.signature
        )
        return SmileID.api.getJobStatus(request: jobStatusRequest)
    }
}
