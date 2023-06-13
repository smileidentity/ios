import SwiftUI

struct InstructionsView: View {
    @ObservedObject private(set) var model: SelfieCaptureViewModel
    @State private var debounceTimer: Timer?
    @State private var directive: LocalizedStringKey = "Instructions.Start"
    var body: some View {
        Text(SmileIDResourcesHelper.localizedString(for: directive.stringKey))
            .multilineTextAlignment(.center)
            .foregroundColor(SmileID.theme.accent)
            .font(SmileID.theme.header4)
            .frame(maxWidth: 300)
            .transition(.slide)
            .onReceive(model.$faceDetectionState, perform: {_ in
                faceDetectionState()
            })
    }
}

extension InstructionsView {
    func faceDetectionState() {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0, repeats: false) { _ in
            switch model.faceDetectionState {
            case .smileFrame:
                directive = "Instructions.Smile"
            case .sceneUnstable:
                directive = "Instructions.Unstable"
            case .faceDetectionErrored:
                directive = "Instructions.UnknownError"
            case .noFaceDetected:
                directive = "Instructions.Start"
            case .faceDetected:
                if model.hasDetectedValidFace && model.faceDetectionState == .smileFrame {
                    directive = "Instructions.Smile"
                } else if model.isAcceptableBounds == .detectedFaceOffCentre {
                    directive = "Instructions.UnableToDetectFace"
                } else if model.isAcceptableBounds == .detectedFaceTooSmall {
                    directive = "Instructions.FaceFar"
                } else if model.isAcceptableBounds == .detectedFaceTooLarge {
                    directive = "Instructions.FaceClose"
                } else {
                    directive = "Instructions.Capturing"
                }
            case .multipleFacesDetected:
                directive = "Instructions.MultipleFaces"
            case .finalFrame:
                directive = "Instructions.Smile"
            }
        }
    }
}

struct InstructionsView_Previews: PreviewProvider {
    static var previews: some View {
        InstructionsView(model: SelfieCaptureViewModel(userId: UUID().uuidString, jobId: UUID().uuidString,
                                                       isEnroll: false))
    }
}
