@testable import SmileIDUI
import SwiftUI
import XCTest

class SmileIDCaptureScreenTests: XCTestCase {
    func testContinueButtonIsClickable() {
        var continueCallCount = 0
        
        let screen = SmileIDCaptureScreen(
            scanType: .documentFront,
            onContinue: { continueCallCount += 1 }
        )
        
        screen.onContinue()
        
        XCTAssertEqual(continueCallCount, 1)
    }
}