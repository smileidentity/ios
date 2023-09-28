import Foundation

/// The result of a selfie capture session and job submission
public protocol SmartSelfieResultDelegate {
    /// This function is called as a result of a successful selfie capture
    /// - Parameters:
    ///   - selfieImage: The local url of the colour selfie image captured
    ///   - livenessImages: An array of local urls of images captured for liveness checks
    ///   - jobStatusResponse: The response object after submitting the jib
    func didSucceed(
        selfieImage: URL,
        livenessImages: [URL],
        jobStatusResponse: JobStatusResponse
    )

    /// An error occurred during the selfie capture session
    /// - Parameter error: The error returned from a failed selfie capture
    func didError(error: Error)
}

/// The result of a smart selfie capture without job submission
internal protocol SelfieImageCaptureDelegate: AnyObject {
    func didCapture(selfie: Data, livenessImages: [Data])
}
