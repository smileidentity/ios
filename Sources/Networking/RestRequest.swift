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
        self.url = url
        self.method = method
        self.headers = headers
        self.queryParameters = queryParameters
        self.body = try encoder.encode(body)
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
