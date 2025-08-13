import XCTest

@testable import SmileIDNavigation

final class SmileIDNavigationTests: XCTestCase {

	private var coordinator: DefaultNavigationCoordinator!

	override func setUp() {
		super.setUp()
		coordinator = DefaultNavigationCoordinator()
	}

	override func tearDown() {
		coordinator = nil
		super.tearDown()
	}

	// MARK: - DefaultNavigationCoordinator Tests

	func testInitialState() {
		XCTAssertEqual(coordinator.currentDestination, .instructions)
		XCTAssertTrue(coordinator.path.isEmpty)
	}

	func testNavigateToDestination() {
		coordinator.navigate(to: .capture)

		XCTAssertEqual(coordinator.currentDestination, .capture)
		XCTAssertEqual(coordinator.path.count, 1)
		XCTAssertEqual(coordinator.path[0], .capture)
	}

	func testNavigateToMultipleDestinations() {
		coordinator.navigate(to: .capture)
		coordinator.navigate(to: .preview)
		coordinator.navigate(to: .processing)

		XCTAssertEqual(coordinator.currentDestination, .processing)
		XCTAssertEqual(coordinator.path.count, 3)
		XCTAssertEqual(coordinator.path, [.capture, .preview, .processing])
	}

	func testNavigateUp() {
		coordinator.navigate(to: .capture)
		coordinator.navigate(to: .preview)

		coordinator.navigateUp()

		XCTAssertEqual(coordinator.currentDestination, .capture)
		XCTAssertEqual(coordinator.path.count, 1)
		XCTAssertEqual(coordinator.path[0], .capture)
	}

	func testNavigateUpFromRoot() {
		coordinator.navigateUp()

		XCTAssertEqual(coordinator.currentDestination, .instructions)
		XCTAssertTrue(coordinator.path.isEmpty)
	}

	func testNavigateUpToRoot() {
		coordinator.navigate(to: .capture)

		coordinator.navigateUp()

		XCTAssertEqual(coordinator.currentDestination, .instructions)
		XCTAssertTrue(coordinator.path.isEmpty)
	}

	func testPopToRoot() {
		coordinator.navigate(to: .capture)
		coordinator.navigate(to: .preview)
		coordinator.navigate(to: .processing)

		coordinator.popToRoot()

		XCTAssertEqual(coordinator.currentDestination, .instructions)
		XCTAssertTrue(coordinator.path.isEmpty)
	}

	func testPopToRootFromRoot() {
		coordinator.popToRoot()

		XCTAssertEqual(coordinator.currentDestination, .instructions)
		XCTAssertTrue(coordinator.path.isEmpty)
	}
}
