/// The result of an Enhanced Document Verification

import Foundation
public protocol EnhancedDocumentVerificationResultDelegate: AnyObject {
    /// Delegate method called after a successful Enhanced Document Verification capture and
    /// submission. It indicates that the capture and network requests were successful. The job
    /// may or may not be complete. Use `jobStatusResponse.jobComplete` to check if a job is
    /// complete and `jobStatusResponse.jobSuccess` to check if a job is successful.
    /// - Parameters:
    ///   - selfie: URL of captured selfie JPEG
    ///   - documentFrontImage: URL of captured front document image JPEG
    ///   - documentBackImage: URL of captured back document image JPEG (if applicable)
    ///   - jobStatusResponse: The response from the job status request
    func didSucceed(
        selfie: URL,
        documentFrontImage: URL,
        documentBackImage: URL?,
        jobStatusResponse: EnhancedDocumentVerificationJobStatusResponse
    )

    /// Delegate method called when an error occurs during Document Verification. This may
    /// be as a result of a network failure or an error that occurs during capture, for example not
    /// not having camera permissions.
    /// - Parameter error: The error returned from a failed Document Verification
    func didError(error: Error)
}
