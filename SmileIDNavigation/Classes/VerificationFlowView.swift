import SmileIDUI
import SwiftUI

public struct VerificationFlowView: View {
  private let product: BusinessProduct
  private let onEvent: VerificationEventSink?
  private let onCompletion: VerificationCompletion

  @ObservedObject private var coordinator: VerificationCoordinator

	public init(
    product: BusinessProduct,
    onEvent: VerificationEventSink? = nil,
    onCompletion: @escaping VerificationCompletion
  ) {
    self.product = product
    self.onEvent = onEvent
    self.onCompletion = onCompletion
    self.coordinator = VerificationCoordinator(product: product, eventSink: onEvent, complete: onCompletion)
  }

	public var body: some View {
    PushNavigationContainer(
      coordinator: coordinator,
      titleFor: title(for:),
      makeView: { stepView($0) },
      onCancel: { coordinator.cancel() },
      shouldHideBack: { $0 == .done }
    )
    .onAppear { coordinator.start() }
  }

  @ViewBuilder
  private func stepView(_ step: NavigationDestination) -> some View {
    switch step {
    case .instructions:
      SmileIDInstructionsScreen(
        onContinue: coordinator.goToNext,
        onCancel: {
          coordinator.cancel()
        })
    case .documentInfo:
      EmptyView()
    case .capture(let kind):
      SmileIDCaptureScreen(scanType: .documentBack, onContinue: {
        coordinator.acceptCapture(kind, image: UIImage())
      })
    case .preview(let kind):
      SmileIDPreviewScreen(
        onContinue: {
          coordinator.goToNext()
        },
        onRetry: {
          coordinator.rejectCapture(
            kind
          )
        }
      )
    case .processing:
      SmileIDProcessingScreen(
        onContinue: {
          coordinator.goToNext()
        },
        onCancel: {
          coordinator.cancel()
        })
    case .done:
      SmileIDProcessingScreen(
        onContinue: {},
        onCancel: {
          coordinator.cancel()
        })
    }
  }

  private func image(for kind: CaptureKind) -> UIImage? {
    switch kind {
    case .documentFront: return coordinator.docFrontImage
    case .documentBack: return coordinator.docBackImage
    case .selfie: return coordinator.selfieImage
    }
  }

  private func title(for step: NavigationDestination) -> String {
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
