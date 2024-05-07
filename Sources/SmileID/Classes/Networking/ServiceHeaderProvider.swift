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

public class SmileHeaderAuthInterceptor: ServiceHeaderProvider {

    init() {}
    
    func provide(request: RestRequest) -> [HTTPHeader]? {
        var headers = request.headers ?? []
        if request.body != nil {
            headers.append(.partnerID(value: SmileID.config.partnerId))
            headers.append(.requestSignature(value: ""))
            headers.append(.timestamp(value: ""))
        }
        return headers
    }
}

public class SmileHeaderMetadataProvider: ServiceHeaderProvider {

    init() {}

    func provide(request: RestRequest) -> [HTTPHeader]? {
        var headers = request.headers ?? []
        if request.body != nil {
            headers.append(.sourceSDK(value: "iOS"))
            headers.append(.sourceSDKVersion(value: SmileID.version))
        }
        return headers
    }
}

public extension HTTPHeader {

    static func contentType(value: String) -> HTTPHeader {
        HTTPHeader(name: "Content-Type", value: value)
    }

    static func partnerID(value: String) -> HTTPHeader {
        HTTPHeader(name: "SmileID-Partner-ID", value: value)
    }

    static func requestSignature(value: String) -> HTTPHeader {
        HTTPHeader(name: "SmileID-Request-Signature", value: value)
    }

    static func timestamp(value: String) -> HTTPHeader {
        HTTPHeader(name: "SmileID-Timestamp", value: value)
    }

    static func sourceSDK(value: String) -> HTTPHeader {
        HTTPHeader(name: "SmileID-Source-SDK", value: value)
    }

    static func sourceSDKVersion(value: String) -> HTTPHeader {
        HTTPHeader(name: "SmileID-Source-SDK-Version", value: value)
    }

}
