import SwiftUI

enum SelfieViewModelAction {
    // View Setup Actions
    case onViewAppear
    case windowSizeDetected(CGSize, EdgeInsets)

    // Face Detection Actions
    case activeLivenessCompleted
    case activeLivenessTimeout

    case jobProcessingDone
    case retryJobSubmission

    // Others
    case openApplicationSettings
    case handleError(Error)
}
