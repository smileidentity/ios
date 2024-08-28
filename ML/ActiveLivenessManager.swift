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

class ActiveLivenessManager: ObservableObject {
    private var tasks: [LivenessTask] = []
    private var currentTaskIndex: Int = 0
    weak var model: SelfieViewModelV2?
    var takePhoto: (() -> Void)?

    // MARK: Constants
    private let yawLeftMinThreshold: CGFloat = -0.15
    private let yawLeftMaxThreshold: CGFloat = -0.6
    private let yawRightMinThreshold: CGFloat = 0.15
    private let yawRightMaxThreshold: CGFloat = 0.6
    private let pitchMinThreshold: CGFloat = 0.15
    private let pitchMaxThreshold: CGFloat = 0.6

    // MARK: UI Properties
    @Published private(set) var yawValue: Double = 0.0
    @Published private(set) var yawLeftProgress: Double = 0.0
    @Published private(set) var yawRightProgress: Double = 0.0
    @Published private(set) var rollValue: Double = 0.0
    @Published private(set) var pitchValue: Double = 0.0
    @Published private(set) var pitchProgress: Double = 0.0
    @Published private(set) var faceDirection: FaceDirection = .none

    init() {
        tasks = [.lookLeft, .lookRight, .lookUp].shuffled()
    }

    private(set) var currentTask: LivenessTask?

    private func moveToNextTask() -> Bool {
        guard currentTaskIndex < tasks.count - 1 else {
            return false
        }
        currentTaskIndex += 1
        currentTask = tasks[currentTaskIndex]
        return true
    }
    
    func setInitialTask() {
        currentTask = tasks[currentTaskIndex]
    }

    func runLivenessChecks(with faceGeometryModel: FaceGeometryModel) {
        yawValue = faceGeometryModel.yaw.doubleValue
        rollValue = faceGeometryModel.roll.doubleValue
        pitchValue = faceGeometryModel.pitch.doubleValue

        guard let currentTask = currentTask else { return }

        switch currentTask {
        case .lookLeft:
            if yawLeftProgress < 1.0 {
                yawLeftProgress = normalize(
                    value: faceGeometryModel.yaw.doubleValue,
                    minValue: min(-yawLeftMinThreshold, faceGeometryModel.yaw.doubleValue),
                    maxValue: min(-yawLeftMaxThreshold, faceGeometryModel.yaw.doubleValue)
                )
            } else {
                completeCurrentTask()
            }
        case .lookRight:
            if yawRightProgress < 1.0 {
                yawRightProgress = normalize(
                    value: faceGeometryModel.yaw.doubleValue,
                    minValue: max(yawRightMinThreshold, faceGeometryModel.yaw.doubleValue),
                    maxValue: max(yawRightMaxThreshold, faceGeometryModel.yaw.doubleValue)
                )
            } else {
                completeCurrentTask()
            }
        case .lookUp:
            if pitchProgress < 1.0 {
                pitchProgress = normalize(
                    value: faceGeometryModel.pitch.doubleValue,
                    minValue: max(pitchMinThreshold, faceGeometryModel.yaw.doubleValue),
                    maxValue: max(pitchMaxThreshold, faceGeometryModel.yaw.doubleValue)
                )
            } else {
                completeCurrentTask()
            }
        }
    }
    
    private func normalize(
        value: Double,
        minValue: Double,
        maxValue: Double
    ) -> Double {
        return (value - minValue) / (maxValue - minValue)
    }

    private func completeCurrentTask() {
        takePhoto?()
        takePhoto?()
        
        if !moveToNextTask() {
            // Liveness challenge complete
            model?.perform(action: .activeLivenessCompleted)
            self.currentTask = nil
        }
    }
}
