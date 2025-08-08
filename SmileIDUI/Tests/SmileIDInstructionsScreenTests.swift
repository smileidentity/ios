@testable import SmileIDUI
import SwiftUI
import XCTest

class SmileIDInstructionsScreenTests: XCTestCase {
  func testInitializationWithCustomButtons() {
    var continueCallCount = 0
    var cancelCallCount = 0

    let screen = SmileIDInstructionsScreen(
      onContinue: { continueCallCount += 1 },
      onCancel: { cancelCallCount += 1 },
      continueButton: { Text("Custom Continue") },
      cancelButton: { Text("Custom Cancel") }
    )

    screen.onContinue()
    screen.onCancel()

    XCTAssertEqual(continueCallCount, 1)
    XCTAssertEqual(cancelCallCount, 1)
  }

  func testConvenienceInitializerWithDefaultButtons() {
    var continueCallCount = 0
    var cancelCallCount = 0

    let screen = SmileIDInstructionsScreen(
      onContinue: { continueCallCount += 1 },
      onCancel: { cancelCallCount += 1 }
    )

    screen.onContinue()
    screen.onCancel()

    XCTAssertEqual(continueCallCount, 1)
    XCTAssertEqual(cancelCallCount, 1)
  }
}
