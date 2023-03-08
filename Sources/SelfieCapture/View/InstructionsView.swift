import SwiftUI

struct InstructionsView: View {
    @ObservedObject private(set) var model: SelfieCaptureViewModel
    var body: some View {
        Text(faceDetectionState())
            .font(.system(size: 16))
    }
}

extension InstructionsView {
    func faceDetectionState() -> String {
        switch model.faceDetectionState {
        case .sceneUnstable:
            return "Please keep your hands steady"
        case .faceDetectionErrored:
            return "An unexpected error occurred"
        case .noFaceDetected:
            return "Please look at the camera"
        case .faceDetected:
            if model.hasDetectedValidFace {
                return "Capturing please stay still"
            } else if model.isAcceptableBounds == .detectedFaceTooSmall {
                return "Please bring your face closer to the camera"
            } else if model.isAcceptableBounds == .detectedFaceTooLarge {
                return "Please hold the camera further away from your face"
            } else if model.isAcceptableBounds == .detectedFaceOffCentre {
                return "Please center your face in the frame"
            } else if !model.isAcceptableRoll || !model.isAcceptableYaw {
                return "Please look straight at the camera"
            } else if !model.isAcceptableQuality {
                return "Image quality too low"
            } else {
                return "We cannot take your photo right now"
            }
        case .multipleFacesDetected:
            return "Please ensure only one face is in the oval"
        case .finalFrame:
            return "Please smile for the camera"
        }
    }
}

struct InstructionsView_Previews: PreviewProvider {
    static var previews: some View {
        InstructionsView(model: SelfieCaptureViewModel(userId: UUID().uuidString, sessionId: UUID().uuidString, isEnroll: false))
    }
}
