import Foundation
import Combine

public protocol SmileIdentityServiceable {
    func authenticate(request: AuthenticationRequest) -> AnyPublisher<AuthenticationResponse, Error>
    func prepUpload(request: PrepUploadRequest) -> AnyPublisher<PrepUploadResponse, Error>
    func upload(zip: Data, to url: String) -> AnyPublisher<Bool, Error>
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

    public func upload(zip: Data, to url: String) -> AnyPublisher<Bool, Error> {
        return put(to: url, with: zip)
    }
}
