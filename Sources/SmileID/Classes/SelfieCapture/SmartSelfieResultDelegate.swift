import Foundation

/// The result of a selfie capture session and job submission
public protocol SmartSelfieResultDelegate {
    /// This function is called as a result of a successful selfie capture
    /// - Parameters:
    ///   - selfieImage: The local url of the colour selfie image captured
    ///   - livenessImages: An array of local urls of images captured for liveness checks
    ///   - didSubmitJob: Indicates whether the job was submitted to the SmileID backend (e.g. it would be false in offline mode)
    func didSucceed(
        selfieImage: URL,
        livenessImages: [URL],
        didSubmitSmartSelfieJob: Bool
    )

    /// An error occurred during the selfie capture session
    /// - Parameter error: The error returned from a failed selfie capture
    func didError(error: Error)
}
