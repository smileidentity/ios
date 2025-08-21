import SmileIDUI
import SwiftUI

public struct VerificationFlowView: View {
  @Backport.StateObject private var viewModel: VerificationFlowViewModel

  public init(
    product: BusinessProduct,
    onEvent: VerificationEventSink? = nil,
    onCompletion: @escaping VerificationCompletion
  ) {
    _viewModel = Backport.StateObject(wrappedValue: VerificationFlowViewModel(
      product: product,
      onEvent: onEvent,
      onCompletion: onCompletion
    ))
  }

  public var body: some View {
    PushNavigationContainer(
      coordinator: viewModel.coordinator,
      titleFor: viewModel.title(for:),
      makeView: { stepView($0) },
      onCancel: { viewModel.cancel() }
    )
    .onAppear { viewModel.start() }
  }

  @ViewBuilder
  private func stepView(_ step: NavigationDestination) -> some View {
    switch step {
    case .instructions:
      SmileIDInstructionsScreen(
        onContinue: viewModel.goToNext,
        onCancel: {
          viewModel.cancel()
        })
    case .documentInfo:
      EmptyView()
    case .capture(let kind):
      SmileIDCaptureScreen(
        scanType: .documentBack,
        onContinue: {
          viewModel.acceptCapture(kind, image: UIImage())
        })
    case .preview(let kind):
      SmileIDPreviewScreen(
        onContinue: {
          viewModel.goToNext()
        },
        onRetry: {
          viewModel.rejectCapture(
            kind
          )
        }
      )
    case .processing:
      SmileIDProcessingScreen(
        onContinue: {
          viewModel.goToNext()
        },
        onCancel: {
          viewModel.cancel()
        })
    case .done:
      SmileIDProcessingScreen(
        onContinue: {},
        onCancel: {
          viewModel.cancel()
        })
    }
  }
}
