import Foundation

enum SelfieViewModelAction {
    // View Setup Actions
    case windowSizeDetected(CGRect)

    // Face Detection Actions
    case activeLivenessCompleted
    case activeLivenessTimeout

    // Others
    case setupDelayTimer
    case openApplicationSettings
    case handleError(Error)
}
