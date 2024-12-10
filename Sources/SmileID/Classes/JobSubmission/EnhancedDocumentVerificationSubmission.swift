//
//  EnhancedDocumentVerificationSubmission.swift
//  Pods
//
//  Created by Japhet Ndhlovu on 12/5/24.
//

public class EnhancedDocumentVerificationSubmission: BaseDocumentVerificationSubmission<EnhancedDocumentVerificationResult> {
    // MARK: - Initialization
    
    public init(
        jobId: String,
        userId: String,
        countryCode: String,
        documentType: String?,
        allowNewEnroll: Bool,
        documentFrontFile: URL,
        selfieFile: URL,
        documentBackFile: URL? = nil,
        livenessFiles: [URL]? = nil,
        extraPartnerParams: [String: String],
        metadata: [Metadatum]? = nil
    ) {
        super.init(
            jobId: jobId,
            userId: userId,
            jobType: .enhancedDocumentVerification,
            countryCode: countryCode,
            documentType: documentType,
            allowNewEnroll: allowNewEnroll,
            documentFrontFile: documentFrontFile,
            selfieFile: selfieFile,
            documentBackFile: documentBackFile,
            livenessFiles: livenessFiles,
            extraPartnerParams: extraPartnerParams,
            metadata: metadata
        )
    }

    
    public override func createResultInstance(
        selfieFile: URL,
        documentFrontFile: URL,
        livenessFiles: [URL]?,
        documentBackFile: URL?,
        didSubmitJob: Bool
    ) -> EnhancedDocumentVerificationResult {
        return EnhancedDocumentVerificationResult(
            captureData: DocumentCaptureResult(
                selfieImage: selfieFile,
                livenessImages: livenessFiles,
                frontImage: documentFrontFile,
                backImage: documentBackFile
            ),
            didSubmitJob: didSubmitJob
        )
    }
}
