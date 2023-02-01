import Foundation
import Combine

class URLSessionRestServiceClient: NSObject, RestServiceClient {
    let session: URLSessionPublisher

    public init(session: URLSessionPublisher = URLSession.shared) {
        self.session = session
    }

    func send<T: Decodable>(request: RestRequest) -> AnyPublisher<T, Error> {
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let urlRequest = try request.getURLRequest()
            return session.send(request: urlRequest)
                .tryMap(checkStatusCode)
                .decode(type: T.self, decoder: decoder)
                .mapError(mapToAPIError)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    private func mapToAPIError(_ error: Error) -> APIError {
        if let decodingError = error as? DecodingError {
            return .decode(decodingError)
        } else if let error = error as? APIError {
            return error
        } else {
            return .unknown(error.localizedDescription)
        }
    }

    private func checkStatusCode(_ element: URLSession.DataTaskPublisher.Output) throws -> Data {
        guard let httpResponse = element.response as? HTTPURLResponse,
              httpResponse.isSuccess else {
            throw APIError.httpStatus((element.response as? HTTPURLResponse)?.statusCode ?? 500, element.data)
        }

        return element.data
    }
}

extension HTTPURLResponse {
    var isSuccess: Bool {
        let successCodes = Array(200...299)
        return successCodes.contains(statusCode)
    }
}
