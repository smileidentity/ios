import XCTest
@testable import SmileIDNavigation

final class FlowBuilderDSLTests: XCTestCase {
    func testDSLBuildSuccess() {
        let builder = SmileIDFlowBuilder()
        builder.screens {
            instructions { instr in
                instr.showAttribution = true
            }
            capture { cap in
                cap.mode = .selfie
                cap.selfie { selfie in
                    selfie.allowAgentMode = false
                }
            }
            preview { prev in
                prev.allowRetake = true
            }
        }
        let result = builder.build()
        switch result {
        case .success(let config):
            XCTAssertEqual(config.steps.count, 3, "Expected three steps from DSL")
            // Validate first step is instructions
            if case let .instructions(instructionsConfig) = config.steps[0] {
                XCTAssertTrue(instructionsConfig.showAttribution)
            } else { XCTFail("First step should be instructions") }
            // Validate capture step
            if case let .capture(captureConfig) = config.steps[1] {
                XCTAssertEqual(captureConfig.mode, .selfie)
                XCTAssertNotNil(captureConfig.selfie, "Selfie config expected when mode is .selfie")
                XCTAssertEqual(captureConfig.selfie?.allowAgentMode, false)
            } else { XCTFail("Second step should be capture") }
            // Validate preview step
            if case let .preview(previewConfig) = config.steps[2] {
                XCTAssertTrue(previewConfig.allowRetake)
            } else { XCTFail("Third step should be preview") }
        case .invalid(let state):
            XCTFail("Expected success, got invalid: \(state.issues.map { $0.message }.joined(separator: ", "))")
        }
    }

    func testDSLEmptyScreensIsInvalid() {
        let builder = SmileIDFlowBuilder()
        // Intentionally do not add screens
        let result = builder.build()
        switch result {
        case .invalid(let state):
            XCTAssertTrue(state.issues.contains { $0 is EmptyScreensBlockIssue }, "Expected EmptyScreensBlockIssue for no DSL screens")
        case .success:
            XCTFail("Expected invalid build when no screens configured")
        }
    }

    func testDSLCaptureRequiresSelfieConfigWhenModeSelfie() {
        let builder = SmileIDFlowBuilder()
        builder.screens {
            capture { cap in
                cap.mode = .selfie
                // Omit selfie builder intentionally to force validation issue
            }
        }
        let result = builder.build()
        switch result {
        case .success(let config):
            // Configuration builds, but FlowValidator should mark invalid when rendered
            let validation = FlowValidator.shared.validate(configuration: config)
            if case .invalid(let issues) = validation {
                XCTAssertTrue(issues.contains { $0 is InvalidSelfieCaptureConfigIssue }, "Expected InvalidSelfieCaptureConfigIssue")
            } else {
                XCTFail("Expected invalid configuration due to missing selfie config")
            }
        case .invalid(let state):
            XCTFail("Builder-level invalid unexpected: \(state.issues.map { $0.message })")
        }
    }
}
