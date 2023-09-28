import Foundation

struct RestRequest: Equatable {
    var url: URL
    var method: RestMethod
    var headers: [HTTPHeader]?
    var body: Data?
    var queryParameters: [HTTPQueryParameters]?

    init(
        url: URL,
        method: RestMethod,
        headers: [HTTPHeader]? = nil,
        queryParameters: [HTTPQueryParameters]? = nil
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.queryParameters = queryParameters
    }

    init(
        url: URL,
        method: RestMethod,
        headers: [HTTPHeader]? = nil,
        queryParameters: [HTTPQueryParameters]? = nil,
        body: Data
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.queryParameters = queryParameters
        self.body = body
    }

    init<T: Encodable>(
        url: URL,
        method: RestMethod,
        headers: [HTTPHeader]? = nil,
        queryParameters: [HTTPQueryParameters]? = nil,
        body: T
    ) throws {
        let encoder = JSONEncoder()
        self.url = url
        self.method = method
        self.headers = headers
        self.queryParameters = queryParameters
        self.body = try encoder.encode(body)
    }
}

extension RestRequest {
    func getURLRequest() throws -> URLRequest {
        let fullURL = try buildURL(with: url)
        var urlRequest = URLRequest(url: fullURL)
        urlRequest.allHTTPHeaderFields = headers?.toDictionary()
        urlRequest.httpMethod = method.httpMethod
        urlRequest.httpBody = body
        return urlRequest
    }

    func getUploadRequest() throws -> URLRequest {
        var urlRequest = URLRequest(url: url)
        urlRequest.allHTTPHeaderFields = headers?.toDictionary()
        urlRequest.httpMethod = method.httpMethod
        return urlRequest
    }

    private func buildURL(with url: URL) throws -> URL {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        components?.queryItems = queryParameters?.flatMap { queryParam in
            queryParam.values.map {
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
        rawValue.uppercased()
    }
}
