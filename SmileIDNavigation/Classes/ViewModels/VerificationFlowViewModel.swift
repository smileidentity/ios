import SwiftUI

@MainActor
public final class VerificationFlowViewModel: ObservableObject {
  public let product: BusinessProduct
  public let onEvent: VerificationEventSink?
  public let onCompletion: VerificationCompletion

  // Coordinator remains responsible for navigation orchestration
  public let coordinator: VerificationCoordinator

  public init(
    product: BusinessProduct,
    onEvent: VerificationEventSink? = nil,
    onCompletion: @escaping VerificationCompletion
  ) {
    self.product = product
    self.onEvent = onEvent
    self.onCompletion = onCompletion
    self.coordinator = VerificationCoordinator(
      product: product,
      eventSink: onEvent,
      complete: onCompletion
    )
  }

  // MARK: - Routing proxies

  func start() { coordinator.start() }
  func cancel() { coordinator.cancel() }
  func goToNext() { coordinator.goToNext() }
  func goBack() { coordinator.goBack() }
  func acceptCapture(_ kind: CaptureKind, image: UIImage) { coordinator.acceptCapture(kind, image: image) }
  func rejectCapture(_ kind: CaptureKind) { coordinator.rejectCapture(kind) }

  // MARK: - Presentation helpers moved out of the View

  func image(for kind: CaptureKind) -> UIImage? {
    switch kind {
    case .documentFront: return coordinator.docFrontImage
    case .documentBack: return coordinator.docBackImage
    case .selfie: return coordinator.selfieImage
    }
  }

  func title(for step: NavigationDestination) -> String {
    switch step {
    case .instructions: return "Instructions"
    case .documentInfo: return "Document Info"
    case .capture(.documentFront): return "Front of Document"
    case .capture(.documentBack): return "Back of Document"
    case .capture(.selfie): return "Selfie"
    case .preview(let kind): return "Preview \(kindTitle(kind))"
    case .processing: return "Submitting…"
    case .done: return "Done"
    }
  }

  private func kindTitle(_ kind: CaptureKind) -> String {
    switch kind {
    case .documentFront: return "Front"
    case .documentBack: return "Back"
    case .selfie: return "Selfie"
    }
  }
}
