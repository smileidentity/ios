import XCTest
@testable import SmileID

class BaseTestCase: XCTestCase {

    var dependencyContainer: DependencyContainer!

    override func setUpWithError() throws {
        dependencyContainer = DependencyContainer()
        DependencyAutoResolver.set(resolver: dependencyContainer)
    }

    override func tearDownWithError() throws {
        DependencyAutoResolver.reset()
    }
}
