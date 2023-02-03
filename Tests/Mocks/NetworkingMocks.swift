import Foundation
import Combine
@testable import SmileIdentity

class MockServiceHeaderProvider: ServiceHeaderProvider {
    var expectedHeaders = [HTTPHeader(name: "", value: "")]
    func provide(request: RestRequest) -> [HTTPHeader]? {
        return expectedHeaders
    }
}


class MockURLSessionPublisher: URLSessionPublisher {

    var expectedData = Data()
    var expectedResponse = URLResponse()

    func send(request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
        return Result.Publisher((expectedData, expectedResponse))
            .eraseToAnyPublisher()
    }
}
