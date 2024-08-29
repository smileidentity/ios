import Foundation
import Vision

/// Represents the different tasks in an active liveness check.
enum LivenessTask {
    case lookLeft
    case lookRight
    case lookUp

    /// The user-friendly instruction for each task.
    var instruction: String {
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

class LivenessCheckManager: ObservableObject {
    private var livenessTaskSequence: [LivenessTask] = []
    private var currentTaskIndex: Int = 0
    weak var selfieViewModel: SelfieViewModelV2?
    var captureImage: (() -> Void)?

    // MARK: Constants
    
    /// The minimum threshold for yaw (left-right head movement)
    private let minYawAngleThreshold: CGFloat = 0.15
    /// The maximum threshold for yaw (left-right head movement)
    private let maxYawAngleThreshold: CGFloat = 0.6
    /// The minimum threshold for pitch (up-down head movement)
    private let minPitchAngleThreshold: CGFloat = 0.15
    /// The maximum threshold for pitch (up-down head movement)
    private let maxPitchAngleThreshold: CGFloat = 0.6

    // MARK: Face Orientation Properties
    @Published private(set) var yawAngle: Double = 0.0
    @Published private(set) var rollAngle: Double = 0.0
    @Published private(set) var pitchAngle: Double = 0.0
    @Published private(set) var  faceDirection: FaceDirection = .none

    /// Initializes the LivenessCheckManager with a shuffled set of tasks.
    init() {
        livenessTaskSequence = [.lookLeft, .lookRight, .lookUp].shuffled()
    }

    /// The current liveness task.
    private(set) var currentTask: LivenessTask?

    /// Advances to the next task in the sequence
    /// - Returns: `true` if there is a next task, `false` if all tasks are completed.
    private func  advanceToNextTask() -> Bool {
        guard currentTaskIndex < livenessTaskSequence.count - 1 else {
            return false
        }
        currentTaskIndex += 1
        currentTask = livenessTaskSequence[currentTaskIndex]
        return true
    }

    /// Sets the initial task for the liveness check.
    func initiateLivenessCheck() {
        currentTask = livenessTaskSequence[currentTaskIndex]
    }
    
    /// Processes face geometry data and checks for task completion
    /// - Parameter faceGeometry: The current face geometry data.
    func processFaceGeometry(_ faceGeometry: FaceGeometryModel) {
        updateFaceOrientationValues(from: faceGeometry)

        guard let currentTask = currentTask else { return }

        switch currentTask {
        case .lookLeft:
            let yawValue = CGFloat(faceGeometry.yaw.doubleValue)
            if yawValue < -minYawAngleThreshold {
                completeCurrentTask()
            }
        case .lookRight:
            let yawValue = CGFloat(faceGeometry.yaw.doubleValue)
            if yawValue > minYawAngleThreshold {
                 completeCurrentTask()
            }
        case .lookUp:
            let pitchValue = CGFloat(faceGeometry.pitch.doubleValue)
            if pitchValue < -minPitchAngleThreshold {
                completeCurrentTask()
            }
        }
    }

    /// Updates the face orientation values based on the given face geometry.
    /// - Parameter faceGeometry: The current face geometry data.
    private func updateFaceOrientationValues(from faceGeometry: FaceGeometryModel) {
        yawAngle = faceGeometry.yaw.doubleValue
        rollAngle = faceGeometry.roll.doubleValue
        pitchAngle = faceGeometry.pitch.doubleValue
    }

    /// Completes the current task and moves to the next one.
    /// If all tasks are completed, it signals the completion of the liveness challenge.
    private func  completeCurrentTask() {
        captureImage?()
        captureImage?()

        if !advanceToNextTask() {
            // Liveness challenge complete
            selfieViewModel?.perform(action: .activeLivenessCompleted)
            self.currentTask = nil
        }
    }
}
