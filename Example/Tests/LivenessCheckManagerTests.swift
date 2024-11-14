import XCTest

@testable import SmileID

class LivenessCheckManagerTests: XCTestCase {
    private var livenessCheckManager: LivenessCheckManager!
    private var mockDelegate: MockLivenessCheckManagerDelegate!

    override func setUp() {
        livenessCheckManager = LivenessCheckManager()
        mockDelegate = MockLivenessCheckManagerDelegate()
        super.setUp()
    }

    override func tearDown() {
        livenessCheckManager = nil
        mockDelegate = nil
        super.tearDown()
    }

    func testInitializationShufflesTasks() {
        let manager1 = LivenessCheckManager()
        let manager2 = LivenessCheckManager()

        XCTAssertNotEqual(manager1.livenessTaskSequence, manager2.livenessTaskSequence, "Task sequences should be shuffled differently")
    }
}

class MockLivenessCheckManagerDelegate: LivenessCheckManagerDelegate {
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
