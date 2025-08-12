@testable import SmileIDUI
import SwiftUI
import XCTest

class SmileIDPreviewScreenTests: XCTestCase {
  func testContinueButtonIsClickable() {
    var continueCallCount = 0

    let screen = SmileIDPreviewScreen(
      onContinue: { continueCallCount += 1 },
      onRetry: {}
    )

    screen.onContinue()

    XCTAssertEqual(continueCallCount, 1)
  }

  func testRetryButtonIsClickable() {
    var retryCallCount = 0

    let screen = SmileIDPreviewScreen(
      onContinue: {},
      onRetry: { retryCallCount += 1 }
    )

    screen.onRetry()

    XCTAssertEqual(retryCallCount, 1)
  }
}
