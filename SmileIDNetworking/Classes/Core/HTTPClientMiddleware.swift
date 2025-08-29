import Foundation

protocol HTTPClientMiddleware: HTTPClientProtocol {
  var next: HTTPClientProtocol { get }
}
