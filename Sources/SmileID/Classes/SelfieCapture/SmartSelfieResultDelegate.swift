/// The result of a selfie capture session and job submission

import Foundation
public protocol SmartSelfieResultDelegate {
    /// This function is called as a result of a successful selfie capture
    /// - Parameters:
    ///   - selfieImage: The local url of the colour selfie image captured
    ///   - livenessImages: An array of local urls of images captured for liveness checks
    ///   - jobStatusResponse: The response object after submitting the job. If nil, it means API submission was skipped
    func didSucceed(
        selfieImage: URL,
        livenessImages: [URL],
        jobStatusResponse: SmartSelfieJobStatusResponse?
    )

    /// An error occurred during the selfie capture session
    /// - Parameter error: The error returned from a failed selfie capture
    func didError(error: Error)
}
