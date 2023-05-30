import XCTest
@testable import SmileID

class DependencyContainerTests: BaseTestCase {

    func testThatDependancyContainerResolvesCorrectType() {
        mockDependencyContainer.register(TestProtocol.self) {TestClass()}
        let result = mockDependencyContainer.resolve(TestProtocol.self)
        XCTAssert(result is TestClass)
    }

    func testThatDependancyContainerResolvesCorrectWithSingletonType() {
        mockDependencyContainer.register(singleton: TestProtocol.self) {TestClass()}
        let result = mockDependencyContainer.resolve(TestProtocol.self)
        XCTAssert(result is TestClass)
    }

    func testThatDependencyContainerReturnsTrueWhenContainerHasDependency() {
        mockDependencyContainer.register(TestProtocol.self, creation: TestClass.init)
        let result = mockDependencyContainer.has(TestProtocol.self)
        XCTAssert(result)
    }

    func testThatDependencyContainerReturnsFalseWhenContainerDoesNotHaveDepdency() {
        let result = mockDependencyContainer.has(TestProtocol.self)
        XCTAssertFalse(result)
    }
}

private class TestClass: TestProtocol {}
private class TestClass2: TestProtocol {}
private protocol TestProtocol {}
