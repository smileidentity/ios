import SwiftUI

struct SmileIDCaptureScreen<ContinueButton: View>: View {
  let scanType: ScanType
  let onContinue: () -> Void

  @ViewBuilder let continueButton: ContinueButton

  init(
    scanType: ScanType,
    onContinue: @escaping () -> Void,
    @ViewBuilder continueButton: () -> ContinueButton
  ) {
    self.scanType = scanType
    self.onContinue = onContinue
    self.continueButton = continueButton()
  }

  var body: some View {
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
    switch scanType {
    case .documentFront, .documentBack:
      DocumentShapedView()
    case .selfie:
      FaceShapedView()
    }
  }
}

extension SmileIDCaptureScreen where ContinueButton == SmileIDButton {
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
