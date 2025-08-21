import SwiftUI

public struct SmileIDCaptureScreen<ContinueButton: View>: View {
  let scanType: ScanType
  let onContinue: () -> Void
  
	@Backport.StateObject private var viewModel: CaptureScreenViewModel
  @ViewBuilder let continueButton: ContinueButton

  public init(
    scanType: ScanType,
    onContinue: @escaping () -> Void,
    @ViewBuilder continueButton: () -> ContinueButton
  ) {
    self.scanType = scanType
    self.onContinue = onContinue
		self._viewModel = Backport.StateObject(
			wrappedValue: CaptureScreenViewModel(
				scanType: scanType,
				onContinue: onContinue
			)
		)
    self.continueButton = continueButton()
  }

  public var body: some View {
    ZStack {
      SmileIDCameraPreview()
        .edgesIgnoringSafeArea(.all)

      overlayView

      VStack {
        Spacer()

        continueButton
          .padding()
      }
    }
  }

  @ViewBuilder
  private var overlayView: some View {
    switch viewModel.scanType {
    case .documentFront, .documentBack:
      DocumentShapedView()
    case .selfie:
      FaceShapedView()
    }
  }
}

public extension SmileIDCaptureScreen where ContinueButton == SmileIDButton {
  init(
    scanType: ScanType,
    onContinue: @escaping () -> Void
  ) {
    self.init(
      scanType: scanType,
      onContinue: onContinue,
      continueButton: {
        SmileIDButton(text: "Continue", onClick: onContinue)
      }
    )
  }
}

#if DEBUG
  #Preview("Document Front") {
    SmileIDCaptureScreen(
      scanType: .documentFront,
      onContinue: {}
    )
  }

  #Preview("Document Back") {
    SmileIDCaptureScreen(
      scanType: .documentBack,
      onContinue: {}
    )
  }

  #Preview("Selfie") {
    SmileIDCaptureScreen(
      scanType: .selfie,
      onContinue: {}
    )
  }
#endif
