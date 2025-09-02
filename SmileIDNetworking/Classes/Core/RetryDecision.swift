import Foundation

enum RetryDecision {
  case doNotRetry
  case retry(after: TimeInterval)
}
