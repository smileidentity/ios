import Foundation
import SwiftUI
import Combine
import UIKit

public class Router<R: Equatable>: ObservableObject {

    private var privateRoutes: [R] = []

    public var routes: [R] {
        return privateRoutes
    }

    var pushHandler: ((R) -> Void)?
    var popHandler: ((Int, Bool) -> Void)?

    public init(initial: R? = nil) {

        if let initial = initial {
            push(initial)
        }
    }

    public func push(_ route: R) {
        self.privateRoutes.append(route)
        self.pushHandler?(route)
    }

    public func pop(animated: Bool = true) {
        if !self.privateRoutes.isEmpty {
            let popped = self.privateRoutes.removeLast()
            popHandler?(1, animated)
        }
    }

    public func popTo(_ route: R, inclusive: Bool = false, animated: Bool = true) {

        if privateRoutes.isEmpty {
            return
        }

        guard var found = privateRoutes.lastIndex(where: { $0 == route }) else {
            return
        }

        if !inclusive {
            found += 1
        }

        let numToPop = (found..<privateRoutes.endIndex).count
        privateRoutes.removeLast(numToPop)
        popHandler?(numToPop, animated)
    }

    public func onUIKitPop() {
        if !self.privateRoutes.isEmpty {
            let popped = self.privateRoutes.removeLast()
        }
    }
}

