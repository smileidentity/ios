import Combine

protocol JobSubmittable {
    func pollJobStatus(_ authResponse: AuthenticationResponse) -> AnyPublisher<JobStatusResponse, Error>
    func upload(_ prepUploadResponse: PrepUploadResponse, zip: Data) -> AnyPublisher<UploadResponse, Error>
    func prepUpload(_ authResponse: AuthenticationResponse) -> AnyPublisher<PrepUploadResponse, Error>
    func handleRetry()
    func handleClose()
}

extension JobSubmittable {
    func prepUpload(_ authResponse: AuthenticationResponse) -> AnyPublisher<PrepUploadResponse, Error> {
        let prepUploadRequest = PrepUploadRequest(partnerParams: authResponse.partnerParams,
                                                  timestamp: authResponse.timestamp,
                                                  signature: authResponse.signature)
        return SmileID.api.prepUpload(request: prepUploadRequest)
    }

    func upload(_ prepUploadResponse: PrepUploadResponse, zip: Data) -> AnyPublisher<UploadResponse, Error> {
        return SmileID.api.upload(zip: zip, to: prepUploadResponse.uploadUrl)
            .eraseToAnyPublisher()
    }

    func pollJobStatus(_ authResponse: AuthenticationResponse) -> AnyPublisher<JobStatusResponse, Error> {
        let jobStatusRequest = JobStatusRequest(userId: authResponse.partnerParams.userId,
                                                jobId: authResponse.partnerParams.jobId,
                                                includeImageLinks: false,
                                                includeHistory: false,
                                                timestamp: authResponse.timestamp,
                                                signature: authResponse.signature)

        let publisher = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .setFailureType(to: Error.self)
            .flatMap { _ in SmileID.api.getJobStatus(request: jobStatusRequest) }
            .first(where: { response in
                return response.jobComplete})
            .timeout(.seconds(10),
                     scheduler: DispatchQueue.main,
                     options: nil,
                     customError: { SmileIDError.jobStatusTimeOut })

        return publisher.eraseToAnyPublisher()
    }
}
