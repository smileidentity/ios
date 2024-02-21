import Combine

public class OfflineMode {

    static func submitJob(
        jobId: String,
        deleteFilesOnSuccess: Bool // todo - to be used in next pr
    ) {
        Task {
            do {
                let authRequest = try LocalStorage.fetchAuthenticationRequestFile(jobId: jobId)
                let authResponse = try await SmileID.api.authenticate(
                    request: authRequest
                ).async()
                let prepUploadRequest = try LocalStorage.fetchPrepUploadFile(jobId: jobId)
                let prepUploadResponse = try await SmileID.api.prepUpload(
                    request: prepUploadRequest
                ).async()
                let zip = try LocalStorage.fetchUploadZip(jobId: jobId)
                let response = try await SmileID.api.upload(
                    zip: zip,
                    to: prepUploadResponse.uploadUrl
                ).async()
            }
        }
    }
}
