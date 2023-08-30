import Foundation
import SwiftUI
import Combine
import UIKit

public class Router<R: Equatable>: ObservableObject {
    private (set) var routes: [R] = []
    var pushHandler: ((R) -> Void)?
    var popHandler: ((Int, Bool) -> Void)?

    public init(initial: R? = nil) {

        if let initial = initial {
            push(initial)
        }
    }

    public func push(_ route: R) {
        self.routes.append(route)
        self.pushHandler?(route)
    }

    public func pop(animated: Bool = true) {
        if !self.routes.isEmpty {
            let popped = self.routes.removeLast()
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
            let popped = self.routes.removeLast()
        }
    }
}

