@testable import SmileID
import XCTest

class BaseTestCase: XCTestCase {
  var mockDependencyContainer: DependencyContainer!

  override func setUpWithError() throws {
    mockDependencyContainer = DependencyContainer()
    DependencyAutoResolver.set(resolver: mockDependencyContainer)
  }

  override func tearDownWithError() throws {
    DependencyAutoResolver.reset()
  }
}
