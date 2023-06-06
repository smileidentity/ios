import Foundation

/// The result of a selfie capture session
public protocol SmartSelfieResultDelegate: AnyObject {
    /// This function is called as a result of a successful selfie capture
    /// - Parameters:
    ///   - selfieImage: A colour selfie image
    ///   - livenessImages: An array of a series of greyscaled images captured for liveness checks
    func didSucceed(selfieImage: Data,
                    livenessImages: [Data],
                    jobStatusResponse: JobStatusResponse)

    /// An error occured during the selfie capture session
    /// - Parameter error: The error returned from a failed selfie capture
    func didError(error: Error)
}
