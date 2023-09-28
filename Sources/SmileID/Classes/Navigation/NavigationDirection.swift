import Foundation

enum NavigationDirection: Equatable {
    case back
    case forward(destination: NavigationDestination, style: NavigationStyle)

    static func ==(lhs: NavigationDirection, rhs: NavigationDirection) -> Bool {
        switch (lhs, rhs) {
        case (.back, .back):
            return true
        default:
            return false
        }
    }
}
