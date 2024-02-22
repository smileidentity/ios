import XCTest
@testable import SmileID

class DependencyContainerTests: BaseTestCase {

    func testThatDependencyContainerResolvesCorrectType() {
        dependencyContainer.register(TestProtocol.self) { TestClass() }
        let result = dependencyContainer.resolve(TestProtocol.self)
        XCTAssert(result is TestClass)
    }

    func testThatDependencyContainerResolvesCorrectWithSingletonType() {
        dependencyContainer.register(singleton: TestProtocol.self) { TestClass() }
        let result = dependencyContainer.resolve(TestProtocol.self)
        XCTAssert(result is TestClass)
    }

    func testThatDependencyContainerReturnsTrueWhenContainerHasDependency() {
        dependencyContainer.register(TestProtocol.self, creation: TestClass.init)
        let result = dependencyContainer.has(TestProtocol.self)
        XCTAssert(result)
    }

    func testThatDependencyContainerReturnsFalseWhenContainerDoesNotHaveDepdency() {
        let result = dependencyContainer.has(TestProtocol.self)
        XCTAssertFalse(result)
    }
}

private class TestClass: TestProtocol {}

private class TestClass2: TestProtocol {}

private protocol TestProtocol {}
