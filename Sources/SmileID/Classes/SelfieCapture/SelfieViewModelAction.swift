import SwiftUI

enum SelfieViewModelAction {
    // View Setup Actions
    case onViewAppear
    case windowSizeDetected(CGSize, EdgeInsets)

    // Others
    case openApplicationSettings
    case handleError(Error)
}
