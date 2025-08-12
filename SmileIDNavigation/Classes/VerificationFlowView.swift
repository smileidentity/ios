import SmileIDUI
import SwiftUI

struct VerificationFlowView: View {
  private let config: VerificationConfig
  private let onEvent: VerificationEventSink?
  private let onCompletion: VerificationCompletion

  @Backport.StateObject private var coordinator: VerificationCoordinator

  init(
    config: VerificationConfig,
    onEvent: VerificationEventSink? = nil,
    onCompletion: @escaping VerificationCompletion
  ) {
    self.config = config
    self.onEvent = onEvent
    self.onCompletion = onCompletion
    _coordinator = .init(
      wrappedValue: VerificationCoordinator(
        config: config,
        eventSink: onEvent,
        complete: onCompletion
      )
    )
  }

  var body: some View {
    NavigationView {
      contentView
        .navigationBarTitle(
          title(for: coordinator.currentStep)
        )
        .navigationBarItems(
          leading: Group {
            if coordinator.canGoBack {
              Button("Back") { coordinator.goBack() }
            }
          },
          trailing: Button("Cancel") { coordinator.cancel() }
        )
    }
    .onAppear { coordinator.start() }
  }

  @ViewBuilder
  private var contentView: some View {
    switch coordinator.currentStep {
    case .instructions:
      SmileIDInstructionsScreen {
        coordinator.goToNext()
      } onCancel: {
        coordinator.cancel()
      }
    case .documentInfo:
      EmptyView()
    case .capture(let captureKind):
      SmileIDCaptureScreen(scanType: .documentBack) {
        coordinator.acceptCapture(captureKind, image: UIImage())
      }
    case .preview(let captureKind):
      SmileIDPreviewScreen {
        coordinator.goToNext()
      } onRetry: {
        coordinator.rejectCapture(captureKind)
      }
    case .processing:
      SmileIDProcessingScreen {
        coordinator.goToNext()
      } onCancel: {
        coordinator.cancel()
      }
      //		case .done:
      //			SmileIDProcessingScreen {
      //			} onCancel: {
      //				coordinator.cancel()
      //			}
    }
  }

  private func image(for kind: CaptureKind) -> UIImage? {
    switch kind {
    case .documentFront: coordinator.docFrontImage
    case .documentBack: coordinator.docBackImage
    case .selfie: coordinator.selfieImage
    }
  }

  private func title(for step: Step) -> String {
    switch step {
    case .instructions: return "Instructions"
    case .documentInfo: return "Document Info"
    case .capture(.documentFront): return "Front of Document"
    case .capture(.documentBack): return "Back of Document"
    case .capture(.selfie): return "Selfie"
    case .preview(let kind): return "Preview \(kindTitle(kind))"
    case .processing: return "Submitting..."
      // case .done: return "Done"
    }
  }

  private func kindTitle(_ kind: CaptureKind) -> String {
    switch kind {
    case .documentFront: "Front"
    case .documentBack: "Back"
    case .selfie: "Selfie"
    }
  }
}

#if DEBUG
  #Preview {
    VerificationFlowView(
      config: VerificationConfig(
        product: VerificationProduct(
          requiresDocInfo: false,
          requiresDocFront: true,
          requiresDocBack: true,
          requiresSelfie: true
        )
      ),
      onEvent: { event in
        print(event.label)
      },
      onCompletion: { result in
        switch result {
        case .success:
          print("success")
        case .failure:
          print("failure")
        }
      }
    )
  }
#endif
