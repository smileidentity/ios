import Foundation
/// The result of a document capture session
public protocol DocumentCaptureResultDelegate: AnyObject {
    /// Delegate method called after a successful Document Verification capture and submission.
    /// It indicates that the capture and network requests were successful. The job may or may not
    /// be complete. Use `jobStatusResponse.jobComplete` to check if a job is complete and
    /// `jobStatusResponse.jobSuccess` to check if a job is successful.
    /// - Parameters:
    ///   - selfie: Jpg data of selfie
    ///   - documentFrontImage: Jpg data of the front of the image
    ///   - documentBackImage: Jpg data of the back of the image
    ///   - jobStatusResponse: An object that represent the status of a job.
    func didSucceed(selfie: URL,
                    documentFrontImage: URL,
                    documentBackImage: URL?,
                    jobStatusResponse: JobStatusResponse)

    /// Delegate method called when an error occurs during the selfie capture session. This may
    /// be as a result of a network failure or an error that occurs during capture, for example not
    /// not having camera permissions.
    /// - Parameter error: The error returned from a failed selfie capture
    func didError(error: Error)

}
