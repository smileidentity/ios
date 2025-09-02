import Foundation

protocol RequestBuilding {
  func makeURLRequest(
    baseURL: URL,
    endpoint: some Endpoint,
    config: NetworkConfig
  ) throws -> URLRequest
}
