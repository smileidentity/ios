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
    private let yawMinThreshold: CGFloat = 0.15
    private let yawMaxThreshold: CGFloat = 0.6
    private let pitchMinThreshold: CGFloat = 0.15
    private let pitchMaxThreshold: CGFloat = 0.6

    // MARK: UI Properties
    @Published private(set) var yawValue: Double = 0.0
    @Published private(set) var rollValue: Double = 0.0
    @Published private(set) var pitchValue: Double = 0.0
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
            let yawValue = CGFloat(faceGeometryModel.yaw.doubleValue)
            if yawValue < -yawMinThreshold {
                completeCurrentTask()
            }
        case .lookRight:
            let yawValue = CGFloat(faceGeometryModel.yaw.doubleValue)
            if yawValue > yawMinThreshold {
                completeCurrentTask()
            }
        case .lookUp:
            let pitchValue = CGFloat(faceGeometryModel.pitch.doubleValue)
            if pitchValue < -pitchMinThreshold {
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
