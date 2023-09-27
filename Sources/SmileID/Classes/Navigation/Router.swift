import SwiftUI
import Combine
import UIKit

public class Router<R: Equatable>: ObservableObject {
    private (set) var routes: [R] = []
    var pushHandler: ((R, Bool) -> Void)?
    var popHandler: ((Int, Bool) -> Void)?
    var presentHandler: ((R) -> Void)?
    var dismissHandler: (() -> Void)?

    public init(initial: R? = nil) {

        if let initial = initial {
            push(initial)
        }
    }

    public func present(_ route: R) {
        presentHandler?(route)
    }

    public func dismiss() {
        dismissHandler?()
        routes = []
    }

    public func push(_ route: R, animated: Bool = true) {
        self.routes.append(route)
        self.pushHandler?(route, animated)
    }

    public func pop(animated: Bool = true) {
        if !self.routes.isEmpty {
            routes.removeLast()
            popHandler?(1, animated)
        }
    }

    public func popTo(_ route: R, inclusive: Bool = false, animated: Bool = true) {

        if routes.isEmpty {
            return
        }

        guard var numFound = routes.lastIndex(where: { $0 == route }) else {
            return
        }

        if !inclusive {
            numFound += 1
        }

        let numToPop = (numFound..<routes.endIndex).count
        routes.removeLast(numToPop)
        popHandler?(numToPop, animated)
    }

    public func onUIKitPop() {
        if !self.routes.isEmpty {
            routes.removeLast()
        }
    }
}
