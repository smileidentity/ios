import Foundation

/// The result of a selfie capture session and job submission
public protocol SmartSelfieResultDelegate {
    /// This function is called as a result of a successful selfie capture
    /// - Parameters:
    ///   - selfieImage: The local url of the colour selfie image captured
    ///   - livenessImages: An array of local urls of images captured for liveness checks
    ///   - apiResponse: The response from the REST API. This will be null if offline mode is
    ///   enabled and the network request failed. In that case, you must use [SmileID.submitJob]
    ///   to submit the job to the SmileID API when internet connectivity is restored.
    func didSucceed(
        selfieImage: URL,
        livenessImages: [URL],
        apiResponse: SmartSelfieResponse?
    )

    /// An error occurred during the selfie capture session
    /// - Parameter error: The error returned from a failed selfie capture
    func didError(error: Error)
}
