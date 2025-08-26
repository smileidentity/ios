import Foundation

protocol Endpoint {
  associatedtype Response: Decodable
  var method: HTTPMethod { get }
  var path: String { get }
  var query: [String: String]? { get }
  var headers: [String: String]? { get }
  var body: HTTPBody? { get }
  var requiresAuth: Bool { get }
  var signing: SigningRequirement { get }
  var encryption: EncryptionRequirement { get }
}
