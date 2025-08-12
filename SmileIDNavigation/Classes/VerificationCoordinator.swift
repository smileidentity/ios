import SwiftUI

enum CaptureKind: String, Hashable, Codable, Sendable {
  case documentFront
  case documentBack
  case selfie
}

enum Step: Hashable, Codable, Sendable {
  case instructions
  case documentInfo
  case capture(CaptureKind)
  case preview(CaptureKind)
  case processing
  case done
}

struct VerificationConfig {
  public var showInstructions: Bool = true
  public var product: VerificationProduct

  public init(showInstructions: Bool = true, product: VerificationProduct) {
    self.showInstructions = showInstructions
    self.product = product
  }
}

enum VerificationEvent {
  case started(product: VerificationProduct)
  case stepChanged(Step)
  case captured(kind: CaptureKind)
  case submitted
  case succeeded(submissionId: String)
  case failed(message: String)
  case cancelled

  var label: String {
    switch self {
    case .started(let product):
      return "Started"
    case .stepChanged(let step):
      return "Step Changed - \(step.hashValue)"
    case .captured(let kind):
      return "Captured - \(kind.rawValue)"
    case .submitted:
      return "Submitted"
    case .succeeded(let submissionId):
      return "Succeeded"
    case .failed(let message):
      return "Failed"
    case .cancelled:
      return "Cancelled"
    }
  }
}

public struct VerificationSuccess: Sendable, Equatable {
  public let submissionId: String
}

enum VerificationError: Error, Equatable, Sendable {
  case cancelled
  case network(String)
  case invalidCapture(String)
  case unknown(String)
}

/// Supported product combos
public struct VerificationProduct: Sendable, Equatable {
  public let requiresDocInfo: Bool
  public let requiresDocFront: Bool
  public let requiresDocBack: Bool
  public let requiresSelfie: Bool
  public init(requiresDocInfo: Bool, requiresDocFront: Bool, requiresDocBack: Bool, requiresSelfie: Bool) {
    self.requiresDocInfo = requiresDocInfo
    self.requiresDocFront = requiresDocFront
    self.requiresDocBack = requiresDocBack
    self.requiresSelfie = requiresSelfie
  }
}

typealias VerificationCompletion = (Result<VerificationSuccess, VerificationError>) -> Void
typealias VerificationEventSink = (VerificationEvent) -> Void

@MainActor
final class VerificationCoordinator: ObservableObject {
  @Published private(set) var currentStep: Step = .instructions

  // Internal route and index
  private var route: [Step] = []
  private var index: Int = 0 {
    didSet {
      if index >= 0, index < route.count {
        currentStep = route[index]
      }
    }
  }

  // Collected artifacts
  @Published private(set) var docInfo: [String: String] = [:]
  @Published private(set) var docFrontImage: UIImage?
  @Published private(set) var docBackImage: UIImage?
  @Published private(set) var selfieImage: UIImage?

  // Config & callbacks
  let config: VerificationConfig
  let eventSink: VerificationEventSink?
  let complete: VerificationCompletion

  init(
    config: VerificationConfig,
    eventSink: VerificationEventSink? = nil,
    complete: @escaping VerificationCompletion
  ) {
    self.config = config
    self.eventSink = eventSink
    self.complete = complete
  }

  // MARK: Lifecycle

  func start() {
    eventSink?(.started(product: config.product))
    buildRoute()
    index = 0
    emitStep()
  }

  func cancel() {
    eventSink?(.cancelled)
    complete(.failure(.cancelled))
  }

  // MARK: Route building

  private func buildRoute() {
    // build initial route
    var steps: [Step] = []
    if config.showInstructions { steps.append(.instructions) }
    if config.product.requiresDocInfo { steps.append(.documentInfo) }
    if config.product.requiresDocFront { steps.append(.capture(.documentFront)) }
    if config.product.requiresDocFront { steps.append(.preview(.documentFront)) }
    if config.product.requiresDocBack { steps.append(.capture(.documentBack)) }
    if config.product.requiresDocBack { steps.append(.preview(.documentBack)) }
    if config.product.requiresSelfie {
      steps.append(.capture(.selfie))
      steps.append(.preview(.selfie))
    }
    steps.append(.processing)
    steps.append(.done)

    route = steps
  }
}

// MARK: Navigation helpers

extension VerificationCoordinator {
  var canGoBack: Bool { index > 0 && route[index] != .done }

  func goBack() {
    guard canGoBack else { return }
    index -= 1
    emitStep()
  }

  func goToNext() {
    guard index + 1 < route.count else { return }
    index += 1
    emitStep()
  }

  private func goTo(step: Step) {
    if let found = route.firstIndex(of: step) {
      index = found
      emitStep()
    }
  }

  private func emitStep() {
    eventSink?(.stepChanged(currentStep))
  }

  func goBackToCapture(_ kind: CaptureKind) {
    // Find the nearest capture step before the current index
    if let captureIndex = route[..<index].lastIndex(of: .capture(kind)) {
      index = captureIndex
      emitStep()
    }
  }

  // MARK: Data mutations from screens

  func documentInfoCompleted(_ info: [String: String]) {
    docInfo = info
    goToNext()
  }

  func acceptCapture(_ kind: CaptureKind, image: UIImage) {
    switch kind {
    case .documentFront: docFrontImage = image
    case .documentBack: docBackImage = image
    case .selfie: selfieImage = image
    }

    eventSink?(.captured(kind: kind))
    goToNext() // move to preview
  }

  public func rejectCapture(_ kind: CaptureKind) {
    // Clear the stored image and return to capture
    switch kind {
    case .documentFront: docFrontImage = nil
    case .documentBack: docBackImage = nil
    case .selfie: selfieImage = nil
    }
    goBackToCapture(kind)
  }
}
