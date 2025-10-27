@testable import SmileIDNavigation
import XCTest

final class FlowStepTests: XCTestCase {
  func testFlowStepEquality() {
    let a: FlowStep = .instructions(InstructionsScreenConfiguration(showAttribution: true))
    let b: FlowStep = .instructions(InstructionsScreenConfiguration(showAttribution: true))
    XCTAssertEqual(a, b)
    XCTAssertEqual(a.type, .instructions)
  }

  func testInvalidPreviewBeforeCaptureOrder() {
    let steps: [FlowStep] = [
      .preview(PreviewScreenConfiguration()),
      .capture(CaptureScreenConfiguration(mode: .selfie, selfie: SelfieCaptureConfig()))
    ]
    let config = FlowConfiguration(steps: steps)
    let validation = FlowValidator.shared.validate(configuration: config)
    if case .invalid(let issues) = validation {
      XCTAssertTrue(issues.contains { $0.message.contains("Preview screen appears before Capture") })
    } else {
      XCTFail("Expected invalid due to screen order")
    }
  }

  func testNavigationAdvancesThroughSteps() {
    let steps: [FlowStep] = [
      .instructions(InstructionsScreenConfiguration()),
      .capture(CaptureScreenConfiguration(mode: .selfie, selfie: SelfieCaptureConfig())),
      .preview(PreviewScreenConfiguration())
    ]
    let config = FlowConfiguration(steps: steps)
    let manager = FlowNavigationManager(configuration: config)
    XCTAssertEqual(manager.currentScreenIndex, 0)
    manager.navigateToNext(currentScreenType: .instructions, result: .consent(granted: true, timestamp: 1))
    XCTAssertEqual(manager.currentScreenIndex, 1)
    manager.navigateToNext(currentScreenType: .capture, result: .selfieCapture(imageUri: "uri", livenessImages: [], qualityScore: 0.8))
    XCTAssertEqual(manager.currentScreenIndex, 2)
    manager.navigateToNext(currentScreenType: .preview)
    // After last step completion, index should remain at last (2) and flow result fired via onResult (not asserted here)
    XCTAssertEqual(manager.currentScreenIndex, 2)
  }
}
