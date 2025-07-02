@testable import SmileID
import XCTest

class RestartableTimerTests: XCTestCase {
  var timer: RestartableTimer!

  override func setUp() {
    super.setUp()
    timer = RestartableTimer(
      timeInterval: 1.0,
      target: self,
      selector: #selector(TimerTarget.timerFired))
  }

  override func tearDown() {
    timer = nil
    super.tearDown()
  }

  func testTimerInitialization() {
    XCTAssertFalse(timer.isValid, "Timer should be initially invalid")
  }

  func testTimerStart() {
    timer.restart()
    XCTAssertTrue(timer.isValid, "Timer should be valid after starting")
  }

  func testTimerStop() {
    timer.restart()
    timer.stop()
    XCTAssertFalse(timer.isValid, "Timer should be invalid after stopping")
  }

  func testTimerRestart() {
    timer.restart()
    timer.stop()
    timer.restart()
    XCTAssertTrue(timer.isValid, "Timer should be valid after restarting")
  }
}

class TimerTarget {
  @objc func timerFired() {
    // This function will be called when the timer fires
  }
}
