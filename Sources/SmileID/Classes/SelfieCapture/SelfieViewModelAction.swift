import SwiftUI

enum SelfieViewModelAction {
    // View Setup Actions
    case onViewAppear
    case windowSizeDetected(CGSize, EdgeInsets)

    // Job Submission Actions
    case cancelSelfieCapture
    case retryJobSubmission

    // Others
    case openApplicationSettings
    case handleError(Error)
}
