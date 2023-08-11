import Combine
import Foundation

public protocol SmileIDServiceable {
    func authenticate(request: AuthenticationRequest) -> AnyPublisher<AuthenticationResponse, Error>
    func prepUpload(request: PrepUploadRequest) -> AnyPublisher<PrepUploadResponse, Error>
    func upload(zip: Data, to url: String) -> AnyPublisher<UploadResponse, Error>
    func getJobStatus(request: JobStatusRequest) -> AnyPublisher<JobStatusResponse, Error>
    func doEnhancedKycAsync(request: EnhancedKycRequest) -> AnyPublisher<EnhancedKycAsyncResponse, Error>
    func getServices() -> AnyPublisher<ServicesResponse, Error>
}

public class SmileIDService: SmileIDServiceable, ServiceRunnable {
    public func getServices() -> AnyPublisher<ServicesResponse, Error> {
        return get(to: "/v1/services")
    }

    @Injected var serviceClient: RestServiceClient
    typealias PathType = String

    public func authenticate(request: AuthenticationRequest) -> AnyPublisher<AuthenticationResponse, Error> {
        return post(to: "auth_smile", with: request)
    }

    public func prepUpload(request: PrepUploadRequest) -> AnyPublisher<PrepUploadResponse, Error> {
        return post(to: "upload", with: request)
    }

    public func upload(zip: Data, to url: String) -> AnyPublisher<UploadResponse, Error> {
        return upload(data: zip, to: url, with: .put)
    }

    public func getJobStatus(request: JobStatusRequest) -> AnyPublisher<JobStatusResponse, Error> {
        return post(to: "job_status", with: request)
    }

    /// Query the Identity Information of an individual using their ID number from a supported ID Type. Return the
    /// personal information of the individual found in the database of the ID authority. The final result is delivered
    /// to the url provided in the request's `callbackUrl` (which is required for this request)
    ///
    /// - Requires: The `callbackUrl` must be set on the `request`
    /// - Parameter request: The Enhanced KYC request
    /// - Returns: A response indicating whether the request was successfully submitted or not
    public func doEnhancedKycAsync(request: EnhancedKycRequest) -> AnyPublisher<EnhancedKycAsyncResponse, Error> {
        return post(to: "async_id_verification", with: request)
    }
}
