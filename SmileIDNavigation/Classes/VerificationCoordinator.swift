import SwiftUI

@MainActor
public final class VerificationCoordinator: ObservableObject {
  @Published private(set) var currentDestination: NavigationDestination = .instructions

  // Internal route and index
  private var route: [NavigationDestination] = []
  private var index: Int = 0 {
    didSet {
      if index >= 0, index < route.count {
        currentDestination = route[index]
      }
    }
  }

  // Flow state (extracted from Coordinator responsibilities)
  let state: VerificationFlowState

  // Config & callbacks
  let product: BusinessProduct
  let eventSink: VerificationEventSink?
  let complete: VerificationCompletion

  public init(
    product: BusinessProduct,
    state: VerificationFlowState,
    eventSink: VerificationEventSink? = nil,
    complete: @escaping VerificationCompletion
  ) {
    self.product = product
    self.state = state
    self.eventSink = eventSink
    self.complete = complete
  }

  // MARK: Lifecycle

  func start() {
    eventSink?(.started(product: product))
    buildRoute()
    index = 0
    emitDestination()
  }

  func cancel() {
    eventSink?(.cancelled)
    complete(.failure(.cancelled))
  }

  // MARK: Route building

  private func buildRoute() {
    route = product.generateRoute()
  }
}

// MARK: Navigation helpers

extension VerificationCoordinator {
  var canGoBack: Bool { index > 0 && route[index] != .done }

  func goBack() {
    guard canGoBack else { return }
    index -= 1
    emitDestination()
  }

  func goToNext() {
    guard index + 1 < route.count else { return }
    index += 1
    emitDestination()
  }

  private func goTo(destination: NavigationDestination) {
    if let found = route.firstIndex(of: destination) {
      index = found
      emitDestination()
    }
  }

  private func emitDestination() {
    eventSink?(.destinationChanged(currentDestination))
  }

  func goBackToCapture(_ kind: CaptureKind) {
    // Find the nearest capture step before the current index
    if let captureIndex = route[..<index].lastIndex(of: .capture(kind)) {
      index = captureIndex
      emitDestination()
    }
  }

  // MARK: Data mutations from screens

  func documentInfoCompleted(_ info: [String: String]) {
    state.docInfo = info
    goToNext()
  }

  func acceptCapture(_ kind: CaptureKind, image: UIImage) {
    switch kind {
    case .documentFront: state.docFrontImage = image
    case .documentBack: state.docBackImage = image
    case .selfie: state.selfieImage = image
    }

    eventSink?(.captured(kind: kind))
    goToNext() // move to preview
  }

  func rejectCapture(_ kind: CaptureKind) {
    // Clear the stored image and return to capture
    switch kind {
    case .documentFront: state.docFrontImage = nil
    case .documentBack: state.docBackImage = nil
    case .selfie: state.selfieImage = nil
    }
    goBackToCapture(kind)
  }
}
