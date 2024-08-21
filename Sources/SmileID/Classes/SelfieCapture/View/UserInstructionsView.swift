import SwiftUI

struct UserInstructionsView: View {
    @ObservedObject var model: SelfieViewModelV2

    var body: some View {
        Text(directive())
            .font(.title)
            .foregroundColor(.white)
            .padding()
    }
}

extension UserInstructionsView {
    func directive() -> String {
        switch model.faceDetectedState {
        case .faceDetected:
            if model.hasDetectedValidFace {
                return "Please take your photo"
            } else if model.isAcceptableBounds == .detectedFaceTooSmall {
                return "Please bring your face closer to the camera"
            } else if model.isAcceptableBounds == .detectedFaceTooLarge {
                return "Please hold the camera further from your face"
            } else if model.isAcceptableBounds == .detectedFaceOffCentre {
                return "Please move your face to the center of the frame"
            } else if !model.isAcceptableQuality {
                return "Image quality is too low"
            } else {
                return "We cannot take your photo right now"
            }
        case .noFaceDetected:
            return "Please look at the camera"
        case .faceDetectionErrored:
            return "An unexpected error ocurred"
        }
    }
}
