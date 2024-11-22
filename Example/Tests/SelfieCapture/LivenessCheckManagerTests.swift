import XCTest

@testable import SmileID

class LivenessCheckManagerTests: XCTestCase {
    private var livenessCheckManager: LivenessCheckManager!
    private var mockTimer: MockTimer!
    private var dispatchQueueMock: DispatchQueueMock!
    private var mockDelegate: MockLivenessCheckManagerDelegate!
    private let taskTimeout: Int = 120

    override func setUp() {
        super.setUp()
        mockTimer = MockTimer()
        dispatchQueueMock = DispatchQueueMock()
        livenessCheckManager = LivenessCheckManager(
            taskTimer: mockTimer,
            taskTimeoutDuration: TimeInterval(taskTimeout),
            dispatchQueue: dispatchQueueMock,
            livenessTaskSequence: LivenessTask.allCases
        )
        mockDelegate = MockLivenessCheckManagerDelegate()
        livenessCheckManager.delegate = mockDelegate
    }

    override func tearDown() {
        livenessCheckManager = nil
        mockTimer = nil
        dispatchQueueMock = nil
        mockDelegate = nil
        super.tearDown()
    }

    func testInitializationShufflesTasks() {
        let manager1 = LivenessCheckManager()
        let manager2 = LivenessCheckManager()

        XCTAssertNotEqual(
            manager1.livenessTaskSequence, manager2.livenessTaskSequence,
            "Task sequences should be shuffled differently")
    }

    func testInitiateSetsCurrentTask() {
        livenessCheckManager.initiateLivenessCheck()
        XCTAssertNotNil(
            livenessCheckManager.currentTask,
            "Current task should be set after initiating liveness check.")
    }

    func testCompletesAllLivenessTasksInSequence() {
        livenessCheckManager.initiateLivenessCheck()

        XCTAssertEqual(livenessCheckManager.currentTask, .lookLeft)

        // complete look left
        let lookLeftFaceGeometry = FaceGeometryData(
            boundingBox: .zero,
            roll: 0,
            yaw: -0.3,
            pitch: 0,
            direction: .none
        )
        livenessCheckManager.processFaceGeometry(lookLeftFaceGeometry)
        XCTAssertTrue(mockDelegate.didCompleteLivenessTaskCalled, "Delegate should be notified of task completed")
        XCTAssertEqual(
            livenessCheckManager.lookLeftProgress, 1.0, "Look left progress should be complete")

        // advance to next task
        XCTAssertEqual(livenessCheckManager.currentTask, .lookRight)

        // complete look right
        let lookRightFaceGeometry = FaceGeometryData(
            boundingBox: .zero,
            roll: 0,
            yaw: 0.3,
            pitch: 0,
            direction: .none
        )
        livenessCheckManager.processFaceGeometry(lookRightFaceGeometry)
        XCTAssertTrue(mockDelegate.didCompleteLivenessTaskCalled, "Delegate should be notified of task completed")
        XCTAssertEqual(
            livenessCheckManager.lookRightProgress, 1.0, "Look right progress should be complete")

        // advance to next task
        XCTAssertEqual(livenessCheckManager.currentTask, .lookUp)

        // complete look up
        let lookUpFaceGeometry = FaceGeometryData(
            boundingBox: .zero,
            roll: 0,
            yaw: 0,
            pitch: -0.3,
            direction: .none
        )
        livenessCheckManager.processFaceGeometry(lookUpFaceGeometry)
        XCTAssertTrue(mockDelegate.didCompleteLivenessTaskCalled, "Delegate should be notified of task completed")
        XCTAssertEqual(
            livenessCheckManager.lookUpProgress, 1.0, "Look up progress should be complete")

        XCTAssertTrue(mockDelegate.didCompleteLivenessChallengeCalled)
    }

    func testTaskTimeout() {
        livenessCheckManager.initiateLivenessCheck()
        for _ in 0..<taskTimeout {
            self.mockTimer.fire()
        }
        XCTAssertTrue(mockDelegate.didTimeoutCalled, "Delegate should be notified of task timeout.")
    }
}

final class MockLivenessCheckManagerDelegate: LivenessCheckManagerDelegate {
    var didCompleteLivenessTaskCalled: Bool = false
    var didCompleteLivenessChallengeCalled: Bool = false
    var didTimeoutCalled: Bool = false

    func didCompleteLivenessTask() {
        didCompleteLivenessTaskCalled = true
    }

    func didCompleteLivenessChallenge() {
        didCompleteLivenessChallengeCalled = true
    }

    func livenessChallengeTimeout() {
        didTimeoutCalled = true
    }
}

final class DispatchQueueMock: DispatchQueueType {
    func asyncAfter(deadline: DispatchTime, execute work: @escaping @Sendable () -> Void) {
        work()
    }

    func async(execute work: @escaping @convention(block) () -> Void) {
        work()
    }
}
