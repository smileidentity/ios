import Foundation

/// The result of a Document Verification
public protocol DocumentVerificationResultDelegate {
    /// Delegate method called after a successful Document Verification capture and submission.
    /// It indicates that the capture and network requests were successful.
    /// - Parameters:
    ///   - selfie: URL of captured selfie JPEG
    ///   - documentFrontImage: URL of captured front document image JPEG
    ///   - documentBackImage: URL of captured back document image JPEG (if applicable)
    ///   - didSubmitDocumentVerificationJob: Indicates whether the job was submitted to the SmileID backend (e.g. it would be false in offline mode)
    func didSucceed(
        selfie: URL,
        documentFrontImage: URL,
        documentBackImage: URL?,
        didSubmitDocumentVerificationJob: Bool
    )

    /// Delegate method called when an error occurs during Document Verification. This may
    /// be as a result of a network failure or an error that occurs during capture, for example not
    /// not having camera permissions.
    /// - Parameter error: The error returned from a failed Document Verification
    func didError(error: Error)
}
