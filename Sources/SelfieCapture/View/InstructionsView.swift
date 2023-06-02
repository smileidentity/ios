import SwiftUI

struct InstructionsView: View {
    @ObservedObject private(set) var model: SelfieCaptureViewModel

    var body: some View {
        Text(SmileIDResourcesHelper.localizedString(for: faceDetectionState().stringKey))
            .multilineTextAlignment(.center)
            .foregroundColor(SmileID.theme.accent)
            .font(SmileID.theme.header4)
            .frame(maxWidth: 300)
            .transition(.slide)
            .animation(.default)
    }
}

extension InstructionsView {
    func faceDetectionState() -> LocalizedStringKey {
        switch model.faceDetectionState {
        case .sceneUnstable:
            return "Instructions.Unstable"
        case .faceDetectionErrored:
            return "Instructions.UnknownError"
        case .noFaceDetected:
            return "Instructions.Start"
        case .faceDetected:
            if model.hasDetectedValidFace {
                return "Instructions.Capturing"
            } else if model.isAcceptableBounds == .detectedFaceOffCentre {
                return "Instructions.UnableToDetectFace"
            } else if model.isAcceptableBounds == .detectedFaceTooSmall {
                return "Instructions.FaceFar"
            } else if model.isAcceptableBounds == .detectedFaceTooLarge {
                return "Instructions.FaceClose"
            } else {
                return "Instructions.Capturing"
            }
        case .multipleFacesDetected:
            return "Instructions.MultipleFaces"
        case .finalFrame:
            return "Instructions.Smile"
        }
    }
}

struct InstructionsView_Previews: PreviewProvider {
    static var previews: some View {
        InstructionsView(model: SelfieCaptureViewModel(userId: UUID().uuidString,
                                                       sessionId: UUID().uuidString,
                                                       isEnroll: false))
    }
}
