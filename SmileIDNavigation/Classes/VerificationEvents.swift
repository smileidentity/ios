import SwiftUI

public enum VerificationEvent {
  case started(product: BusinessProduct)
  case destinationChanged(NavigationDestination)
  case captured(kind: CaptureKind)
  case submitted
  case succeeded(submissionId: String)
  case failed(message: String)
  case cancelled
}

public struct VerificationSuccess: Sendable, Equatable {
  public let submissionId: String

  public init(submissionId: String) {
    self.submissionId = submissionId
  }
}

public enum VerificationError: Error, Equatable, Sendable {
  case cancelled
  case network(String)
  case invalidCapture(String)
  case unknown(String)
}

public typealias VerificationCompletion = (Result<VerificationSuccess, VerificationError>) -> Void
public typealias VerificationEventSink = (VerificationEvent) -> Void
