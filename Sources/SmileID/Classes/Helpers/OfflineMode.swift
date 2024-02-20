import Combine

public class OfflineMode {

    static func submitJob(
        jobId: String,
        deleteFilesOnSuccess: Bool
    ) throws -> AnyPublisher<UploadResponse, Error> {
        return try authentication(jobId: jobId)
            .flatMap { authResponse in
                do {
                    return try self.prepUpload(jobId: jobId, authResponse: authResponse)
                } catch {
                    return Fail(error: error).eraseToAnyPublisher()
                }
            }
            .flatMap { prepUploadResponse in
                do {
                    return try self.upload(jobId: jobId, prepUploadResponse: prepUploadResponse)
                } catch {
                    return Fail(error: error).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

   static private func authentication(
        jobId: String
    ) throws -> AnyPublisher<AuthenticationResponse, Error> {
        let authRequest = try LocalStorage.fetchAuthenticationRequestFile(jobId: jobId)
        return SmileID.api.authenticate(request: authRequest)
    }

    static private func prepUpload(
        jobId: String,
        authResponse: AuthenticationResponse
    ) throws -> AnyPublisher<PrepUploadResponse, Error> {
        let prepUploadRequest = try LocalStorage.fetchPrepUploadFile(jobId: jobId)
        return SmileID.api.prepUpload(request: prepUploadRequest)
    }

    static private func upload(
        jobId: String,
        prepUploadResponse: PrepUploadResponse
    ) throws -> AnyPublisher<UploadResponse, Error> {
        let data = try LocalStorage.fetchUploadZip(jobId: jobId)
        return SmileID.api.upload(zip: data, to: prepUploadResponse.uploadUrl)
    }
}
