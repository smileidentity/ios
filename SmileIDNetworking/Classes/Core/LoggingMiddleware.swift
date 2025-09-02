import Foundation

final class LoggingMiddleware: HTTPClientMiddleware {
  let next: HTTPClientProtocol
  let logger: NetworkLogger
  let redacted: Set<String>

  init(
    next: HTTPClientProtocol,
    logger: NetworkLogger,
    redacted: Set<String>
  ) {
    self.next = next
    self.logger = logger
    self.redacted = redacted
  }

  func send(
    _ request: URLRequest
  ) async throws -> (Data, HTTPURLResponse) {
    logger.logRequest(request, redacted: redacted)
    do {
      let (data, response) = try await next.send(request)
      logger.logResponse(data: data, response: response, redacted: redacted)
      return (data, response)
    } catch {
      logger.logError(error, request: request)
      throw error
    }
  }
}
