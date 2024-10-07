import Foundation

enum SelfieViewModelAction {
    // View Setup Actions
    case onViewAppear
    case windowSizeDetected(CGRect)

    // Face Detection Actions
    case activeLivenessCompleted
    case activeLivenessTimeout

    // Others
    case openApplicationSettings
    case handleError(Error)
}
