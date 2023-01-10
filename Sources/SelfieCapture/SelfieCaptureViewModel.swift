import Foundation
import UIKit

enum SelfieCaptureViewModelAction {
    // View setup and configuration actions
    case windowSizeDetected(CGRect)
    
    // Face detection actions
    case noFaceDetected
    case faceObservationDetected(FaceGeometryModel)
    case faceQualityObservationDetected(FaceQualityModel)
}

final class SelfieCaptureViewModel: ObservableObject {
    //TODO: Dynamically calculate the layout framee
    var faceLayoutGuideFrame = CGRect(x: 0, y: 0, width: 200, height: 300)
    
    @Published private(set) var hasDetectedValidFace: Bool
    @Published private(set) var isAcceptableRoll: Bool {
        didSet {
            calculateDetectedFaceValidity()
        }
    }
    @Published private(set) var isAcceptablePitch: Bool {
        didSet {
            calculateDetectedFaceValidity()
        }
    }
    @Published private(set) var isAcceptableYaw: Bool {
        didSet {
            calculateDetectedFaceValidity()
        }
    }
    @Published private(set) var isAcceptableBounds: FaceBoundsState {
        didSet {
            calculateDetectedFaceValidity()
        }
    }
    @Published private(set) var isAcceptableQuality: Bool {
        didSet {
            calculateDetectedFaceValidity()
        }
    }
    
    @Published private(set) var faceDetectedState: FaceDetectionState
    @Published private(set) var faceGeometryState: FaceObservation<FaceGeometryModel> {
        didSet {
            processUpdatedFaceGeometry()
        }
    }
    
    @Published private(set) var faceQualityState: FaceObservation<FaceQualityModel> {
        didSet {
            processUpdatedFaceQuality()
        }
    }
    
    init() {
        faceDetectedState = .noFaceDetected
        isAcceptableRoll = false
        isAcceptablePitch = false
        isAcceptableYaw = false
        isAcceptableBounds = .unknown
        isAcceptableQuality = false
        
        hasDetectedValidFace = false
        faceGeometryState = .faceNotFound
        faceQualityState = .faceNotFound
    }
    
    func perform(action: SelfieCaptureViewModelAction) {
        switch action {
        case .noFaceDetected:
            print("")
        default:
            break
        }
    }
    
    func processUpdatedFaceGeometry() {
        switch faceGeometryState {
        case .faceNotFound:
            invalidateFaceGeometryState()
        case .errored(let error):
            print(error.localizedDescription)
            invalidateFaceGeometryState()
        case .faceFound(let faceGeometryModel):
            let boundingBox = faceGeometryModel.boundingBox
            let roll = faceGeometryModel.roll.doubleValue
            let pitch = faceGeometryModel.pitch.doubleValue
            let yaw = faceGeometryModel.yaw.doubleValue
            
            updateAcceptableBounds(using: boundingBox)
            updateAcceptableRollPitchYaw(using: roll, pitch: pitch, yaw: yaw)
        }
    }
}

extension SelfieCaptureViewModel {
    func invalidateFaceGeometryState() {
        isAcceptableRoll = false
        isAcceptablePitch = false
        isAcceptableYaw = false
        isAcceptableBounds = .unknown
    }
    
    func calculateDetectedFaceValidity() {
        hasDetectedValidFace =
        isAcceptableBounds == .detectedFaceAppropriateSizeAndPosition &&
        isAcceptableRoll &&
        isAcceptablePitch &&
        isAcceptableYaw &&
        isAcceptableQuality
    }
    
    func updateAcceptableBounds(using boundingBox: CGRect) {
        // First, check face is roughly the same size as the layout guide
        if boundingBox.width > 1.2 * faceLayoutGuideFrame.width {
            isAcceptableBounds = .detectedFaceTooLarge
        } else if boundingBox.width * 1.2 < faceLayoutGuideFrame.width {
            isAcceptableBounds = .detectedFaceTooSmall
        } else {
            // Next, check face is roughly centered in the frame
            if abs(boundingBox.midX - faceLayoutGuideFrame.midX) > 50 {
                isAcceptableBounds = .detectedFaceOffCentre
            } else if abs(boundingBox.midY - faceLayoutGuideFrame.midY) > 50 {
                isAcceptableBounds = .detectedFaceOffCentre
            } else {
                isAcceptableBounds = .detectedFaceAppropriateSizeAndPosition
            }
        }
    }
    
    func updateAcceptableRollPitchYaw(using roll: Double, pitch: Double, yaw: Double) {
        isAcceptableRoll = (roll > 1.2 && roll < 1.6)
        isAcceptablePitch = abs(CGFloat(pitch)) < 0.2
        isAcceptableYaw = abs(CGFloat(yaw)) < 0.15
    }
    
    func processUpdatedFaceQuality() {
        switch faceQualityState {
        case .faceNotFound:
            isAcceptableQuality = false
        case .errored(let error):
            print(error.localizedDescription)
            isAcceptableQuality = false
        case .faceFound(let faceQualityModel):
            if faceQualityModel.quality < 0.2 {
                isAcceptableQuality = false
            }
            isAcceptableQuality = true
        }
    }
}
