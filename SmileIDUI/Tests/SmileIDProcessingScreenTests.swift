import SwiftUI
import XCTest

@testable import SmileIDUI

class SmileIDProcessingScreenTests: XCTestCase {
  func testContinueButtonIsClickable() {
    var continueCallCount = 0

    let screen = SmileIDProcessingScreen(
      onContinue: { continueCallCount += 1 },
      onCancel: {}
    )

    screen.onContinue()

    XCTAssertEqual(continueCallCount, 1)
  }

  func testCancelButtonIsClickable() {
    var cancelCallCount = 0

    let screen = SmileIDProcessingScreen(
      onContinue: {},
      onCancel: { cancelCallCount += 1 }
    )

    screen.onCancel()

    XCTAssertEqual(cancelCallCount, 1)
  }
}
