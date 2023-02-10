import Foundation
import Combine

public protocol SmileIdentityServiceable {
    func authenticate(request: AuthenticationRequest) -> AnyPublisher<AuthenticationResponse, Error>
}

public class SmileIdentityService: SmileIdentityServiceable, ServiceRunnable {
    @Injected var serviceClient: RestServiceClient
    typealias PathType = String

    public func authenticate(request: AuthenticationRequest) -> AnyPublisher<AuthenticationResponse, Error> {
        return post(to: "/v1/auth_smile", with: request)
    }
}
