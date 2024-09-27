import Foundation

enum SelfieViewModelAction {
    // View Setup Actions
    case windowSizeDetected(CGRect)

    // Face Detection Actions
    case updateUserInstruction(SelfieCaptureInstruction?)
    case activeLivenessCompleted
    case activeLivenessTimeout

    // Others
    case setupDelayTimer
    case toggleDebugMode
    case openApplicationSettings
    case handleError(Error)
}
