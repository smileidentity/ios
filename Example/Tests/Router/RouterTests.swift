import XCTest
@testable import SmileID

final class RouterTests: XCTestCase {

    enum Screen {
        case one, two, three
    }

    func testRouterActions() throws {
        let router = Router(initial: Screen.one)
        XCTAssertEqual(router.routes.count, 1)
        XCTAssertEqual(router.routes[0], .one)

        router.push(.two)
        XCTAssertEqual(router.routes.count, 2)
        XCTAssertEqual(router.routes[0], .one)
        XCTAssertEqual(router.routes[1], .two)

        router.push(.three)
        XCTAssertEqual(router.routes.count, 3)
        XCTAssertEqual(router.routes[0], .one)
        XCTAssertEqual(router.routes[1], .two)
        XCTAssertEqual(router.routes[2], .three)

        router.pop()
        XCTAssertEqual(router.routes.count, 2)
        XCTAssertEqual(router.routes[0], .one)
        XCTAssertEqual(router.routes[1], .two)

        router.push(.three)
        router.popTo(.one)
        XCTAssertEqual(router.routes.count, 1)
        XCTAssertEqual(router.routes[0], .one)

        router.popTo(.two)
        XCTAssertEqual(router.routes.count, 1)
        XCTAssertEqual(router.routes[0], .one)

        router.pop()
        XCTAssertEqual(router.routes.count, 0)

        router.popTo(.one)
    }
}
