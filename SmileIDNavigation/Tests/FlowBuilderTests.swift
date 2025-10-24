import XCTest
import SwiftUI
@testable import SmileIDNavigation

final class FlowBuilderTests: XCTestCase {

    func testValidFlowBuild() {
        let builder = SmileIDFlowBuilder()
        builder.instructions { $0.showAttribution = true }
        builder.capture { cap in
            cap.mode = .selfie
            cap.selfie { selfie in selfie.allowAgentMode = false }
        }
        builder.preview { _ in }
        let result = builder.build()
        switch result {
        case .success(let config):
            XCTAssertEqual(config.steps.count, 3)
            XCTAssertEqual(config.steps.map { $0.type }, [.instructions, .capture, .preview])
        default:
            XCTFail("Expected success build")
        }
    }

    func testDuplicateScreensFailValidation() {
        let builder = SmileIDFlowBuilder()
        builder.instructions { _ in }
        builder.instructions { _ in }
        let result = builder.build()
        switch result {
        case .invalid(let state):
            XCTAssertTrue(state.issues.contains { $0.message.contains("Duplicate") })
        default:
            XCTFail("Expected invalid result due to duplicate instructions screens")
        }
    }

    func testSelfieCaptureRequiresConfig() {
        let builder = SmileIDFlowBuilder()
        builder.capture { cap in cap.mode = .selfie } // missing selfie config
        let result = builder.build()
        if case .invalid(let state) = result {
            XCTAssertTrue(state.issues.contains { $0.message.contains("selfie is required") })
        } else {
            XCTFail("Expected invalid build for missing selfie config")
        }
    }

    func testIntegrityHashStable() {
        let builder = SmileIDFlowBuilder()
        builder.instructions { _ in }
        builder.capture { cap in
            cap.mode = .selfie
            cap.selfie { _ in }
        }
        builder.preview { _ in }
        var firstHash: String?
        var secondHash: String?

        builder.onResult = { result in
            if case .success(let data) = result {
                if firstHash == nil { firstHash = data.integrityHash }
                else { secondHash = data.integrityHash }
            }
        }

        // First run
        if case .success(let config) = builder.build() {
            let manager = FlowNavigationManager(configuration: config)
            manager.navigateToNext(currentScreenType: .instructions, result: .consent(granted: true, timestamp: 1))
            manager.navigateToNext(currentScreenType: .capture, result: .selfieCapture(imageUri: "uri", livenessImages: [], qualityScore: 0.9))
            manager.navigateToNext(currentScreenType: .preview)
        } else { XCTFail("Expected success config build") }

        // Second run with same sequence
        if case .success(let config) = builder.build() {
            let manager = FlowNavigationManager(configuration: config)
            manager.navigateToNext(currentScreenType: .instructions, result: .consent(granted: true, timestamp: 1))
            manager.navigateToNext(currentScreenType: .capture, result: .selfieCapture(imageUri: "uri", livenessImages: [], qualityScore: 0.9))
            manager.navigateToNext(currentScreenType: .preview)
        } else { XCTFail("Expected success config build") }

        XCTAssertNotNil(firstHash)
        XCTAssertEqual(firstHash, secondHash, "Integrity hash should be deterministic for identical flows")
    }
}
