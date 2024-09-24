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
    /// The sequence of liveness tasks to be performed.
    private var livenessTaskSequence: [LivenessTask] = []
    /// The index pointing to the current task in the sequence.
    private var currentTaskIndex: Int = 0
    /// The view model associated with the selfie capture process.
    weak var selfieViewModel: SelfieViewModelV2?
    /// A closure to trigger photo capture during the liveness check.
    var captureImage: (() -> Void)?

    // MARK: Constants

    /// The minimum threshold for yaw (left-right head movement)
    private let minYawAngleThreshold: CGFloat = 0.15
    /// The maximum threshold for yaw (left-right head movement)
    private let maxYawAngleThreshold: CGFloat = 0.3
    /// The minimum threshold for pitch (up-down head movement)
    private let minPitchAngleThreshold: CGFloat = 0.15
    /// The maximum threshold for pitch (up-down head movement)
    private let maxPitchAngleThreshold: CGFloat = 0.3

    // MARK: Face Orientation Properties
    @Published var lookLeftProgress: CGFloat = 0.0
    @Published var lookRightProgress: CGFloat = 0.0
    @Published var lookUpProgress: CGFloat = 0.0
    @Published private(set) var faceDirection: FaceDirection = .none

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
        let yawValue = CGFloat(faceGeometry.yaw.doubleValue)
        let pitchValue = CGFloat(faceGeometry.pitch.doubleValue)

        updateFaceOrientationValues(yawValue, pitchValue)
    }

    /// Updates the face orientation values based on the given face geometry.
    /// - Parameter faceGeometry: The current face geometry data.
    private func updateFaceOrientationValues(
        _ yawValue: CGFloat,
        _ pitchValue: CGFloat
    ) {
        guard let currentTask = currentTask else { return }

        switch currentTask {
        case .lookLeft:
            if yawValue < -minYawAngleThreshold {
                let progress = yawValue
                    .normalized(min: -minYawAngleThreshold, max: -maxYawAngleThreshold)
                lookLeftProgress = min(max(lookLeftProgress, progress), 1.0)
                if lookLeftProgress == 1.0 {
                    completeCurrentTask()
                }
            }
        case .lookRight:
            if yawValue > minYawAngleThreshold {
                let progress = yawValue
                    .normalized(min: minYawAngleThreshold, max: maxYawAngleThreshold)
                lookRightProgress = min(max(lookRightProgress, progress), 1.0)
                if lookRightProgress == 1.0 {
                    completeCurrentTask()
                }
            }
        case .lookUp:
            if pitchValue < -minPitchAngleThreshold {
                let progress = pitchValue
                    .normalized(min: -minPitchAngleThreshold, max: -maxPitchAngleThreshold)
                lookUpProgress = min(max(lookUpProgress, progress), 1.0)
                if lookUpProgress == 1.0 {
                    completeCurrentTask()
                }
            }
        }
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

extension CGFloat {
    func normalized(min: CGFloat, max: CGFloat) -> CGFloat {
        return (self - min) / (max - min)
    }
}
