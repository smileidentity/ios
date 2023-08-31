import SwiftUI
import Combine
import UIKit

class Router<R: Equatable>: ObservableObject {
    private (set) var routes: [R] = []
    var pushHandler: ((R) -> Void)?
    var popHandler: ((Int, Bool) -> Void)?
    var presentHandler: ((R) -> Void)?
    var dismissHandler: (() -> Void)?

    init(initial: R? = nil) {

        if let initial = initial {
            push(initial)
        }
    }

    func present(_ route: R) {
        presentHandler?(route)
    }

    func dismiss() {
        dismissHandler?()
        routes = []
    }

    func push(_ route: R) {
        self.routes.append(route)
        self.pushHandler?(route)
    }

    func pop(animated: Bool = true) {
        if !self.routes.isEmpty {
            routes.removeLast()
            popHandler?(1, animated)
        }
    }

    func popTo(_ route: R,
                      inclusive: Bool = false,
                      animated: Bool = true) {

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

    func onUIKitPop() {
        if !self.routes.isEmpty {
            routes.removeLast()
        }
    }
}

