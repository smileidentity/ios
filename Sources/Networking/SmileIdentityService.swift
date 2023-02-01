import Foundation
import Combine

protocol SmileIdentityServiceable {
    func authenticate(request: AuthenticationRequest) -> AnyPublisher<AuthenticationResponse, Error>
}

class SmileIdentityService: SmileIdentityServiceable, ServiceRunnable {
    @Injected var serviceClient: RestServiceClient
    typealias PathType = String

    func authenticate(request: AuthenticationRequest) -> AnyPublisher<AuthenticationResponse, Error> {
        return post(to: "/v1/auth_smile", with: request)
    }
}
