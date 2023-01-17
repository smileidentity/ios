import Foundation
import UIKit
import Combine

enum SelfieCaptureViewModelAction {

    //scene stabilization action
    case sceneUnstable
    // Face detection actions
    case noFaceDetected
    case multipleFacesDetected
    case faceObservationDetected(FaceGeometryModel)
    case faceQualityObservationDetected(FaceQualityModel)
}

final class SelfieCaptureViewModel: ObservableObject {
    var faceLayoutGuideFrame = CGRect.zero
    var viewDelegate: FaceDetectorDelegate? {
        didSet {
            faceDetector.viewDelegate = viewDelegate
        }
    }
    private var frameManager = FrameManager.shared
    private var faceDetector = FaceDetector()
    private var subscribers = Set<AnyCancellable>()
    private let numberOfLivenessImages = 7
    private let livenessImageSize = CGSize(width: 256, height: 256)
    private let selfieImageSize = CGSize(width: 320, height: 320)
    private var currentBuffer: CVPixelBuffer?
    private var livenessImages = [Data]()
    private var lastCaptureTime: Int64 = 0
    private var interCaptureDelay = 350
    
    
    @Published private(set) var hasDetectedValidFace: Bool {
        didSet {
            captureImage()
        }
    }
    @Published private(set) var isAcceptableRoll: Bool {
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

    @Published private(set) var faceDetectionState: FaceDetectionState
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
        faceDetectionState = .noFaceDetected
        isAcceptableRoll = false
        isAcceptableYaw = false
        isAcceptableBounds = .unknown
        isAcceptableQuality = false

        hasDetectedValidFace = false
        faceGeometryState = .faceNotFound
        faceQualityState = .faceNotFound
        faceDetector.model = self
        setupSubscriptions()
    }

    private func setupSubscriptions() {
        frameManager.$sampleBuffer
            .receive(on: DispatchQueue.global())
            .compactMap { return $0 }
            .sink {
                self.faceDetector.detect(pixelBuffer: $0)
                self.currentBuffer = $0
            }
            .store(in: &subscribers)
    }

    func perform(action: SelfieCaptureViewModelAction) {
        switch action {
        case .sceneUnstable:
            publishUnstableSceneObserved()
        case .noFaceDetected:
            publishNoFaceObserved()
        case .multipleFacesDetected:
            publishFaceObservation(.multipleFacesDetected)
        case .faceObservationDetected(let faceGeometry):
            publishFaceObservation(.faceDetected, faceGeometryModel: faceGeometry)
        case .faceQualityObservationDetected(let faceQualityModel):
            publishFaceObservation(.faceDetected, faceQualityModel: faceQualityModel)
        }
    }
    
    private func captureImage() {
        guard let currentBuffer = currentBuffer, hasDetectedValidFace == true, livenessImages.count < numberOfLivenessImages + 1  else {
            return
        }
        guard case let .faceFound(face) = faceGeometryState else {
            return
        }
        while (livenessImages.count < numberOfLivenessImages) && ((Date().millisecondsSince1970 - lastCaptureTime) > interCaptureDelay) {
            guard let image = captureJPGImage(from: currentBuffer, with: livenessImageSize, and: face, isGreyScale: true) else {
                return
            }
            livenessImages.append(image)
            lastCaptureTime = Date().millisecondsSince1970
            saveLivenessImage(data: image)
        }
        
        if (livenessImages.count == numberOfLivenessImages) && ((Date().millisecondsSince1970 - lastCaptureTime) > interCaptureDelay) {
            publishFaceObservation(.finalFrame)
            if faceDetector.detectSmile(imageBuffer: currentBuffer) {
                guard let image = captureJPGImage(from: currentBuffer, with: selfieImageSize, and: face, isGreyScale: false) else {
                    return
                }
                livenessImages.append(image)
                lastCaptureTime = Date().millisecondsSince1970
                saveLivenessImage(data: image)
            }
        }
    }
    
    func saveLivenessImage(data: Data) {
        if let photo = UIImage(data: data) {
            UIImageWriteToSavedPhotosAlbum(photo, nil, nil, nil)
        }
    }

    private func publishUnstableSceneObserved() {
        DispatchQueue.main.async { [self] in
            faceDetectionState = .sceneUnstable
        }
    }

    private func publishNoFaceObserved() {
        DispatchQueue.main.async { [self] in
            faceDetectionState = .noFaceDetected
            faceGeometryState = .faceNotFound
            faceQualityState = .faceNotFound
        }
    }

    private func publishFaceObservation(_ faceDetectionState: FaceDetectionState, faceGeometryModel: FaceGeometryModel? = nil, faceQualityModel: FaceQualityModel? = nil) {
        DispatchQueue.main.async { [self] in
            self.faceDetectionState = faceDetectionState
            if let faceGeometryModel = faceGeometryModel {
                faceGeometryState = .faceFound(faceGeometryModel)
            }
            if let faceQualityModel = faceQualityModel {
                faceQualityState = .faceFound(faceQualityModel)
            }
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
            let yaw = faceGeometryModel.yaw.doubleValue
            updateAcceptableBounds(using: boundingBox)
            updateAcceptableRollYaw(using: roll, yaw: yaw)
        }
    }
}

extension SelfieCaptureViewModel {
    func invalidateFaceGeometryState() {
        isAcceptableRoll = false
        isAcceptableYaw = false
        isAcceptableBounds = .unknown
    }

    func calculateDetectedFaceValidity() {
        hasDetectedValidFace =
        isAcceptableBounds == .detectedFaceAppropriateSizeAndPosition &&
        isAcceptableRoll &&
        isAcceptableYaw &&
        isAcceptableQuality
    }

    func updateAcceptableBounds(using boundingBox: CGRect) {
        if boundingBox.width > 0.7 * faceLayoutGuideFrame.width {
            isAcceptableBounds = .detectedFaceTooLarge
        } else if boundingBox.width < faceLayoutGuideFrame.width * 0.25 {
            isAcceptableBounds = .detectedFaceTooSmall
        } else {
            if abs(boundingBox.midX - faceLayoutGuideFrame.midX) > 50 {
                isAcceptableBounds = .detectedFaceOffCentre
            } else if abs(boundingBox.midY - faceLayoutGuideFrame.midY) > 50 {
                isAcceptableBounds = .detectedFaceOffCentre
            } else {
                isAcceptableBounds = .detectedFaceAppropriateSizeAndPosition
            }
        }
    }

    func updateAcceptableRollYaw(using roll: Double, yaw: Double) {
        isAcceptableRoll = abs(roll) < 0.5
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
            if faceQualityModel.quality < 0.3 {
                isAcceptableQuality = false
            }
            isAcceptableQuality = true
        }
    }
}
