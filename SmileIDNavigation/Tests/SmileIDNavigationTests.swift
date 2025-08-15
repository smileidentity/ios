import UIKit
import XCTest

@testable import SmileIDNavigation

@MainActor
final class SmileIDNavigationTests: XCTestCase {
  private var mockEventSink: [VerificationEvent]!
  private var mockCompletion: Result<VerificationSuccess, VerificationError>?

  override func setUp() {
    super.setUp()
    mockEventSink = []
    mockCompletion = nil
  }

  override func tearDown() {
    mockEventSink = nil
    mockCompletion = nil
    super.tearDown()
  }

  // MARK: - VerificationCoordinator Tests

  func testVerificationCoordinatorInitialization() {
    let config = VerificationConfig(
      showInstructions: true,
      product: VerificationProductBuilder
        .documentVerification()
        .captureOneSide()
        .build()
    )

    let coordinator = VerificationCoordinator(
      config: config,
      eventSink: { self.mockEventSink.append($0) },
      complete: { self.mockCompletion = $0 }
    )

    XCTAssertEqual(coordinator.currentDestination, .instructions)
    XCTAssertTrue(coordinator.docInfo.isEmpty)
    XCTAssertNil(coordinator.docFrontImage)
    XCTAssertNil(coordinator.docBackImage)
    XCTAssertNil(coordinator.selfieImage)
  }

  func testCoordinatorStart() {
    let config = VerificationConfig(
      showInstructions: true,
      product: VerificationProductBuilder
        .documentVerification()
        .captureOneSide()
        .hidePreview()
        .build()
    )

    let coordinator = VerificationCoordinator(
      config: config,
      eventSink: { self.mockEventSink.append($0) },
      complete: { self.mockCompletion = $0 }
    )

    coordinator.start()

    XCTAssertEqual(mockEventSink.count, 2)
    if case .started(let product) = mockEventSink[0] {
      XCTAssertEqual(product, config.product)
    } else {
      XCTFail("Expected started event")
    }

    if case .destinationChanged(let destination) = mockEventSink[1] {
      XCTAssertEqual(destination, .instructions)
    } else {
      XCTFail("Expected destinationChanged event")
    }
  }

  func testCoordinatorCancel() {
    let config = VerificationConfig(
      showInstructions: true,
      product: VerificationProductBuilder
        .documentVerification()
        .captureOneSide()
        .hidePreview()
        .build()
    )

    let coordinator = VerificationCoordinator(
      config: config,
      eventSink: { self.mockEventSink.append($0) },
      complete: { self.mockCompletion = $0 }
    )

    coordinator.cancel()

    XCTAssertEqual(mockEventSink.count, 1)
    if case .cancelled = mockEventSink[0] {
      // Expected
    } else {
      XCTFail("Expected cancelled event")
    }

    XCTAssertNotNil(mockCompletion)
    if case .failure(let error) = mockCompletion {
      XCTAssertEqual(error, .cancelled)
    } else {
      XCTFail("Expected failure with cancelled error")
    }
  }

  func testNavigationFlow() {
    let config = VerificationConfig(
      showInstructions: true,
      product: VerificationProductBuilder
        .documentVerification()
        .captureOneSide()
        .build()
    )

    let coordinator = VerificationCoordinator(
      config: config,
      eventSink: { self.mockEventSink.append($0) },
      complete: { self.mockCompletion = $0 }
    )

    coordinator.start()
    XCTAssertEqual(coordinator.currentDestination, .instructions)

    coordinator.goToNext()
    XCTAssertEqual(coordinator.currentDestination, .capture(.documentFront))

    coordinator.goToNext()
    XCTAssertEqual(coordinator.currentDestination, .preview(.documentFront))
  }

  func testNavigationBackwards() {
    let config = VerificationConfig(
      showInstructions: true,
      product: VerificationProductBuilder
        .documentVerification()
        .captureOneSide()
        .build()
    )

    let coordinator = VerificationCoordinator(
      config: config,
      eventSink: { self.mockEventSink.append($0) },
      complete: { self.mockCompletion = $0 }
    )

    coordinator.start()
    coordinator.goToNext()
    coordinator.goToNext()

    XCTAssertEqual(coordinator.currentDestination, .preview(.documentFront))
    XCTAssertTrue(coordinator.canGoBack)

    coordinator.goBack()
    XCTAssertEqual(coordinator.currentDestination, .capture(.documentFront))
  }
}
