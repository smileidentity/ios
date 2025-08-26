import Foundation

protocol NetworkLogger {
  func logRequest(
    _ request: URLRequest,
    redacted: Set<String>
  )
  func logResponse(
    data: Data,
    response: HTTPURLResponse,
    redacted: Set<String>
  )
  func logError(_ error: Error, request: URLRequest?)
}
