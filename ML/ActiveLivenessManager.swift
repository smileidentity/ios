import Foundation
import Vision

enum LivenessTask {
    case lookLeft
    case lookRight
    case lookUp

    var directive: String {
        switch self {
        case .lookLeft:
            return "Look Left"
        case .lookRight:
            return "Look Right"
        case .lookUp:
            return "Look Up"
        }
    }
}

class ActiveLivenessManager {
    private var tasks: [LivenessTask] = []
    private(set) var currentTaskIndex: Int = 0 {
        didSet {
            model?.perform(action: .updateDirective(currentTask.directive))
        }
    }
    private var livenessPhotos: [UIImage] = []
    weak var model: SelfieViewModelV2?
    var takePhoto: (() -> Void)?

    // MARK: Constants
    private let yawThreshold: CGFloat = 0.5
    private let pitchThreshold: CGFloat = 0.5

    init() {
        tasks = [.lookLeft, .lookRight, .lookUp].shuffled()
    }

    private var currentTask: LivenessTask {
        guard !tasks.isEmpty, currentTaskIndex < tasks.count else {
            return tasks[0]
        }
        return tasks[currentTaskIndex]
    }

    private func moveToNextTask() -> Bool {
        guard currentTaskIndex < tasks.count - 1 else {
            return false
        }
        currentTaskIndex += 1
        return true
    }

    func performLivenessChecks(with faceGeometryModel: FaceGeometryModel) {
        switch currentTask {
        case .lookLeft:
            if CGFloat(faceGeometryModel.yaw.doubleValue) < -yawThreshold {
                completeCurrentTask()
            }
        case .lookRight:
            if CGFloat(faceGeometryModel.yaw.doubleValue) < yawThreshold {
                completeCurrentTask()
            }
        case .lookUp:
            if CGFloat(faceGeometryModel.pitch.doubleValue) > pitchThreshold {
                completeCurrentTask()
            }
        }
    }

    private func completeCurrentTask() {
        takePhoto?()
        takePhoto?()
        
        if !moveToNextTask() {
            // Liveness challenge complete
            print("All steps completed. Photos captured: \(livenessPhotos.count)")
        } else {
            print("Moving to next step: \(currentTask)")
        }
    }
}
