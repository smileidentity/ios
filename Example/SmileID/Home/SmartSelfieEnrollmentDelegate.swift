import Foundation
import SmileID

// We need to define a separate proxy delegate because it's the same protocol for both Enrollment
// and Authentication. However, since the result is still processing, the result parameter is not
// yet populated (which is what contains the jobType). On Enroll, we need to perform a different
// action (namely, save userId to clipboard)
class SmartSelfieEnrollmentDelegate: SmartSelfieResultDelegate {
    let userId: String
    let onEnrollmentSuccess: (
        _ userId: String,
        _ selfieFile: URL,
        _ livenessImages: [URL],
        _ apiResponse: SmartSelfieResponse?
    ) -> Void
    let onError: (Error) -> Void

    init(
        userId: String,
        onEnrollmentSuccess: @escaping (
            _: String,
            _: URL,
            _: [URL],
            _: SmartSelfieResponse?
        ) -> Void,
        onError: @escaping (
            Error
        ) -> Void
    ) {
        self.userId = userId
        self.onEnrollmentSuccess = onEnrollmentSuccess
        self.onError = onError
    }

    func didSucceed(
        selfieImage: URL,
        livenessImages: [URL],
        apiResponse: SmartSelfieResponse?
    ) {
        onEnrollmentSuccess(userId, selfieImage, livenessImages, apiResponse)
    }

    func didError(error: Error) {
        onError(error)
    }
}
