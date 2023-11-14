/// The result of a selfie capture session and Biometric KYC job submission. The Job itself may
/// or may not be complete yet. This can be checked with `jobStatusResponse.jobComplete`. If not
/// yet complete, the job status will need to be fetched again later. If the job is complete, the
/// final job success can be checked with `jobStatusResponse.jobSuccess`.

import Foundation
public protocol BiometricKycResultDelegate {
    /// This function is called as a result of a successful selfie capture and job submission
    /// - Parameters:
    ///   - selfieImage: The local url of the colour selfie image captured
    ///   - livenessImages: An array of local urls of images captured for liveness checks
    ///   - jobStatusResponse: The response object after submitting the jib
    func didSucceed(
        selfieImage: URL,
        livenessImages: [URL],
        jobStatusResponse: BiometricKycJobStatusResponse
    )

    /// An error occurred during the selfie capture session or job submission
    /// - Parameter error: The error returned from a failed selfie capture or job submission
    func didError(error: Error)
}
