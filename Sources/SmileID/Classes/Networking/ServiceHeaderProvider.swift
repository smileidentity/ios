import Foundation

protocol ServiceHeaderProvider {
    func provide(request: RestRequest) -> [HTTPHeader]?
}

public class DefaultServiceHeaderProvider: ServiceHeaderProvider {

    init() {}

    func provide(request: RestRequest) -> [HTTPHeader]? {
        var headers = request.headers ?? []

        if request.body != nil {
            headers.append(.contentType(value: "application/json"))
        }
        return headers
    }

}

public extension HTTPHeader {

    static func contentType(value: String) -> HTTPHeader {
        HTTPHeader(name: "Content-Type", value: value)
    }

}
