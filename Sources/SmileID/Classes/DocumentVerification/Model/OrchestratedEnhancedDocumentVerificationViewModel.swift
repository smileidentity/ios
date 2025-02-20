import Foundation

// swiftlint:disable opening_brace
class OrchestratedEnhancedDocumentVerificationViewModel:
    IOrchestratedDocumentVerificationViewModel<
        EnhancedDocumentVerificationResultDelegate, EnhancedDocumentVerificationJobResult
    >
{
    override func onFinished(delegate: EnhancedDocumentVerificationResultDelegate) {
        if let savedFiles,
           let selfiePath = getRelativePath(from: selfieFile),
           let documentFrontPath = getRelativePath(from: savedFiles.documentFront)
        {
            let documentBackPath = getRelativePath(from: savedFiles.documentBack)
            delegate.didSucceed(
                selfie: selfiePath,
                documentFrontImage: documentFrontPath,
                documentBackImage: documentBackPath,
                didSubmitEnhancedDocVJob: didSubmitJob
            )
        } else if let error {
            // We check error as the 2nd case because as long as jobStatusResponse is not nil, it
            // was a success
            delegate.didError(error: error)
        } else {
            delegate.didError(error: SmileIDError.unknown("Unknown error"))
        }
    }
}
