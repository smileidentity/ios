import Foundation

struct RestRequest: Equatable {
    var url: URL
    var method: RestMethod
    var headers: [HTTPHeader]?
    var body: Data?
    var queryParameters: [HTTPQueryParameters]?

    init(url: URL,
         method: RestMethod,
         headers: [HTTPHeader]? = nil,
         queryParameters: [HTTPQueryParameters]? = nil ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.queryParameters = queryParameters
    }

    init<T: Encodable>(url: URL,
                       method: RestMethod,
                       headers: [HTTPHeader]? = nil,
                       queryParameters: [HTTPQueryParameters]? = nil,
                       body: T) throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        self.url = url
        self.method = method
        self.headers = headers
        self.queryParameters = queryParameters
        self.body = try encoder.encode(body)
    }
}

extension RestRequest {
    func getURLRequest() throws -> URLRequest {
        let headerProvider = DependencyAutoResolver.resolve(ServiceHeaderProvider.self)
        let headers = headerProvider.provide(request: self)
        let fullURL = try buildURL(with: url)
        var urlRequest = URLRequest(url: fullURL)
        urlRequest.allHTTPHeaderFields = headers?.toDictionary()
        urlRequest.httpMethod = method.httpMethod
        urlRequest.httpBody = body
        return urlRequest
    }

    private func buildURL(with url: URL) throws -> URL {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        components?.queryItems = queryParameters?.flatMap { queryParam in
            queryParam.value.map {
                URLQueryItem(name: queryParam.key, value: $0)
            }
        }

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        return url
    }
}

enum RestMethod: String {
    case get, post, put, delete, head
}

extension RestMethod {
    var httpMethod: String {
        return rawValue.uppercased()
    }
}
