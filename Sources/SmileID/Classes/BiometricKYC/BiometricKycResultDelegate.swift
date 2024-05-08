import Foundation

/// The result of a selfie capture session and Biometric KYC job submission.
public protocol BiometricKycResultDelegate {
    /// This function is called as a result of a successful selfie capture and job submission
    /// - Parameters:
    ///   - selfieImage: The local url of the colour selfie image captured
    ///   - livenessImages: An array of local urls of images captured for liveness checks
    ///   - didSubmitBiometricJob: Indicates whether the job was submitted to the SmileID backend (e.g. it would be false in offline mode)
    func didSucceed(
        selfieImage: URL,
        livenessImages: [URL],
        didSubmitBiometricJob: Bool
    )

    /// An error occurred during the selfie capture session or job submission
    /// - Parameter error: The error returned from a failed selfie capture or job submission
    func didError(error: Error)
}
