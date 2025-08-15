import SwiftUI

public struct VerificationConfig {
  public var showInstructions: Bool = true
  public var product: BusinessProduct

  public init(showInstructions: Bool = true, product: BusinessProduct) {
    self.showInstructions = showInstructions
    self.product = product
  }
}


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

  // TODO: Collected artifacts: Consider moving this to view model later.
  @Published private(set) var docInfo: [String: String] = [:]
  @Published private(set) var docFrontImage: UIImage?
  @Published private(set) var docBackImage: UIImage?
  @Published private(set) var selfieImage: UIImage?

  // Config & callbacks
  let config: VerificationConfig
  let eventSink: VerificationEventSink?
  let complete: VerificationCompletion

  public init(
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
    emitDestination()
  }

  func cancel() {
    eventSink?(.cancelled)
    complete(.failure(.cancelled))
  }

  // MARK: Route building

  private func buildRoute() {
    route = config.product.generateRoute(showInstructions: config.showInstructions)
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

  func rejectCapture(_ kind: CaptureKind) {
    // Clear the stored image and return to capture
    switch kind {
    case .documentFront: docFrontImage = nil
    case .documentBack: docBackImage = nil
    case .selfie: selfieImage = nil
    }
    goBackToCapture(kind)
  }
}
