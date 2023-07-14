import Foundation
class DocumentCaptureViewModel: ObservableObject {
    private (set) lazy var cameraManager: CameraManageable = CameraManager()

    var navTitle: String {
        return "Nigeria National ID Card"
    }

    func captureImage() {

    }

    func resetState() {

    }

    func pauseCameraSession() {

    }
}
