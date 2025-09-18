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

extension HTTPHeader {
  public static func contentType(value: String) -> HTTPHeader {
    HTTPHeader(name: "Content-Type", value: value)
  }

  public static func partnerID(value: String) -> HTTPHeader {
    HTTPHeader(name: "SmileID-Partner-ID", value: value)
  }

  public static func requestSignature(value: String) -> HTTPHeader {
    HTTPHeader(name: "SmileID-Request-Signature", value: value)
  }

  public static func timestamp(value: String) -> HTTPHeader {
    HTTPHeader(name: "SmileID-Timestamp", value: value)
  }

  public static func sourceSDK(value: String) -> HTTPHeader {
    HTTPHeader(name: "SmileID-Source-SDK", value: value)
  }

  public static func sourceSDKVersion(value: String) -> HTTPHeader {
    HTTPHeader(name: "SmileID-Source-SDK-Version", value: value)
  }

  public static func requestTimestamp(value: String) -> HTTPHeader {
    HTTPHeader(name: "SmileID-Request-Timestamp", value: value)
  }

  public static func requestMac(value: String) -> HTTPHeader {
    HTTPHeader(name: "SmileID-Request-Mac", value: value)
  }
}
