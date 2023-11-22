/// The result of a Enhanced KYC job submission.
import Foundation
import SmileID

public protocol EnhancedKycResultDelegate {
    /// This function is called as a result of a successful submission
    /// - Parameters:
    ///   - enhancedKycResponse: Enhanced KYC Result
    func didSucceed(
        enhancedKycResponse: EnhancedKycResponse
    )

    /// An error occurred during the job submission
    /// - Parameter error: The error returned from a failed selfie capture or job submission
    func didError(error: Error)
}
