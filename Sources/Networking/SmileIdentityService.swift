import Foundation
import Combine

public protocol SmileIdentityServiceable {
    func authenticate(request: AuthenticationRequest) -> AnyPublisher<AuthenticationResponse, Error>
    func prepUpload(request: PrepUploadRequest) -> AnyPublisher<PrepUploadResponse, Error>
    func upload(zip: Data, to url: String) -> AnyPublisher<UploadResponse, Error>
    func doEnhancedKyc(request: EnhancedKycRequest) -> AnyPublisher<EnhancedKycResponse, Error>
    func getJobStatus(request: JobStatusRequest) -> AnyPublisher<JobStatusResponse, Error>
}

public class SmileIdentityService: SmileIdentityServiceable, ServiceRunnable {
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

    public func doEnhancedKyc(request: EnhancedKycRequest) -> AnyPublisher<EnhancedKycResponse, Error> {
        return post(to: "id_verification", with: request)
    }

    public func getJobStatus(request: JobStatusRequest) -> AnyPublisher<JobStatusResponse, Error> {
        return post(to: "job_status", with: request)
    }
}
