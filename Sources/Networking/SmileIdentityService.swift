import Foundation
import Combine

protocol SmileIdentityServiceable {
    func authenticate(request: AuthenticationRequest) -> AnyPublisher<AuthenticationResponse, Error>
}

class SmileIdentityService: SmileIdentityServiceable {
    func authenticate(request: AuthenticationRequest) -> AnyPublisher<AuthenticationResponse, Error> {
        
    }
}
