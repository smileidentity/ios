import Foundation
import Vision

/// Represents the different tasks in an active liveness check.
enum LivenessTask: CaseIterable {
    case lookLeft
    case lookRight
    case lookUp
}

protocol LivenessManagerProtocol {
    var delegate: LivenessCheckManagerDelegate? { get  set }
    var currentTask: LivenessTask? { get set }
    var lookLeftProgress: CGFloat { get set }
    var lookRightProgress: CGFloat { get set }
    var lookUpProgress: CGFloat { get set }
    func initiateLivenessCheck()
    func processFaceGeometry(_ faceGeometry: FaceGeometryData)
}

protocol LivenessCheckManagerDelegate: AnyObject {
    func didCompleteLivenessTask()
    func didCompleteLivenessChallenge()
    func livenessChallengeTimeout()
}

class LivenessCheckManager: ObservableObject {
    /// The sequence of liveness tasks to be performed.
    private(set) var livenessTaskSequence: [LivenessTask] = []
    /// The index pointing to the current task in the sequence.
    private var currentTaskIndex: Int = 0

    weak var delegate: LivenessCheckManagerDelegate?

    // MARK: Constants
    /// The minimum threshold for yaw (left-right head movement)
    private let minYawAngleThreshold: CGFloat = 0.15
    /// The maximum threshold for yaw (left-right head movement)
    private let maxYawAngleThreshold: CGFloat = 0.3
    /// The minimum threshold for pitch (up-down head movement)
    private let minPitchAngleThreshold: CGFloat = 0.15
    /// The maximum threshold for pitch (up-down head movement)
    private let maxPitchAngleThreshold: CGFloat = 0.3
    /// The timeout duration for each task in seconds.
    private let taskTimeoutDuration: TimeInterval

    // MARK: Face Orientation Properties
    @Published var lookLeftProgress: CGFloat = 0.0
    @Published var lookRightProgress: CGFloat = 0.0
    @Published var lookUpProgress: CGFloat = 0.0

    /// The current liveness task.
    var currentTask: LivenessTask? {
        didSet {
            handleTaskChange()
        }
    }
    /// The timer used for task timeout.
    private let taskTimer: TimerProtocol
    private let dispatchQueue: DispatchQueueType
    private var elapsedTime: TimeInterval = 0.0

    /// Initializes the LivenessCheckManager with a shuffled set of tasks.
    init(
        taskTimer: TimerProtocol = RealTimer(),
        taskTimeoutDuration: TimeInterval = 120,
        dispatchQueue: DispatchQueueType = DispatchQueue.main,
        livenessTaskSequence: [LivenessTask] = LivenessTask.allCases.shuffled()
    ) {
        self.taskTimer = taskTimer
        self.taskTimeoutDuration = taskTimeoutDuration
        self.dispatchQueue = dispatchQueue
        self.livenessTaskSequence = livenessTaskSequence
    }

    /// Cleans up resources when the manager is no longer needed.
    deinit {
        stopTaskTimer()
    }

    /// Resets the task timer to the initial timeout duration.
    private func resetTaskTimer() {
        stopTaskTimer()
        elapsedTime = 0.0

        dispatchQueue.async {
            self.taskTimer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.taskTimerFired()
            }
        }
    }

    private func taskTimerFired() {
        self.elapsedTime += 1
        if self.elapsedTime == self.taskTimeoutDuration {
            self.handleTaskTimeout()
        }
    }

    /// Stops the current task timer.
    private func stopTaskTimer() {
        taskTimer.invalidate()
    }

    /// Handles the timeout event for a task.
    private func handleTaskTimeout() {
        stopTaskTimer()
        delegate?.livenessChallengeTimeout()
    }

    private func handleTaskChange() {
        if currentTask != nil {
            resetTaskTimer()
        } else {
            stopTaskTimer()
        }
    }

    /// Advances to the next task in the sequence
    /// - Returns: `true` if there is a next task, `false` if all tasks are completed.
    private func advanceToNextTask() -> Bool {
        guard currentTaskIndex < livenessTaskSequence.count - 1 else {
            return false
        }
        currentTaskIndex += 1
        currentTask = livenessTaskSequence[currentTaskIndex]
        return true
    }

    /// Sets the initial task for the liveness check.
    func initiateLivenessCheck() {
        currentTask = livenessTaskSequence.first
    }

    /// Processes face geometry data and checks for task completion
    /// - Parameter faceGeometry: The current face geometry data.
    func processFaceGeometry(_ faceGeometry: FaceGeometryData) {
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
                let progress =
                    yawValue
                    .normalized(min: -minYawAngleThreshold, max: -maxYawAngleThreshold)
                lookLeftProgress = min(max(lookLeftProgress, progress), 1.0)
                if lookLeftProgress == 1.0 {
                    completeCurrentTask()
                }
            }
        case .lookRight:
            if yawValue > minYawAngleThreshold {
                let progress =
                    yawValue
                    .normalized(min: minYawAngleThreshold, max: maxYawAngleThreshold)
                lookRightProgress = min(max(lookRightProgress, progress), 1.0)
                if lookRightProgress == 1.0 {
                    completeCurrentTask()
                }
            }
        case .lookUp:
            if pitchValue < -minPitchAngleThreshold {
                let progress =
                    pitchValue
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
    private func completeCurrentTask() {
        delegate?.didCompleteLivenessTask()

        if !advanceToNextTask() {
            // Liveness challenge complete
            delegate?.didCompleteLivenessChallenge()
            self.currentTask = nil
        }
    }
}

extension LivenessCheckManager: LivenessManagerProtocol {}

extension CGFloat {
    func normalized(min: CGFloat, max: CGFloat) -> CGFloat {
        return (self - min) / (max - min)
    }
}
