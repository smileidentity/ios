import Foundation

protocol RetryPolicy {
  func decision(
    for response: HTTPURLResponse?,
    error: Error?,
    attempt: Int
  ) -> RetryDecision
}
