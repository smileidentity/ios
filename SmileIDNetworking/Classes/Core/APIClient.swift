import Foundation

final class APIClient {
  private let config: NetworkConfig
  private let builder: RequestBuilding
  private let client: HTTPClientProtocol // wrapped with middlewares

  init(
    config: NetworkConfig,
    builder: RequestBuilding,
    client: HTTPClientProtocol
  ) {
    self.config = config
    self.builder = builder
    self.client = client
  }

  func send<E: Endpoint>(
    _ endpoint: E
  ) async throws -> E.Response {
    do {
      let request = try builder.makeURLRequest(
        baseURL: config.environment.baseURL,
        endpoint: endpoint,
        config: config
      )
      let (data, response) = try await client.send(request)
      guard (200..<300).contains(response.statusCode) else {
        let apiError = try? JSONDecoder().decode(
          APIErrorPayload.self,
          from: data
        )
        throw NetworkError.server(
          status: response.statusCode,
          code: apiError?.code,
          message: apiError?.message,
          data: data
        )
      }
      do {
        return try JSONDecoder().decode(E.Response.self, from: data)
      } catch {
        throw NetworkError.decodingFailed(underlying: error)
      }
    } catch let error as NetworkError {
      throw error
    } catch let error as URLError {
      throw NetworkError.transport(error)
    } catch {
      throw NetworkError.requestBuildFailed(underlying: error)
    }
  }
}
