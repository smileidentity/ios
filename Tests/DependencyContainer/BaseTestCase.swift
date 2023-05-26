import XCTest
@testable import SmileID

class BaseTestCase: XCTestCase {

    var mockDependencyContainer: DependencyContainer!

    override func setUpWithError() throws {
        mockDependencyContainer = DependencyContainer()
        DependencyAutoResolver.set(resolver: mockDependencyContainer)    }

    override func tearDownWithError() throws {
        DependencyAutoResolver.reset()
    }
}
