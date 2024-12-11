//
//  DocumentVerificationSubmission.swift
//  Pods
//
//  Created by Japhet Ndhlovu on 12/5/24.
//

class DocumentVerificationSubmission: BaseDocumentVerificationSubmission<DocumentVerificationResult> {
    
    public init(
            jobId: String,
            userId: String,
            countryCode: String,
            allowNewEnroll: Bool,
            documentFrontFile: URL,
            selfieFile: URL,
            documentType: String? = nil,
            documentBackFile: URL? = nil,
            livenessFiles: [URL]? = nil,
            extraPartnerParams: [String: String],
            metadata: [Metadatum]? = nil
        ) {
            super.init(
                jobId: jobId,
                userId: userId,
                jobType: .documentVerification,
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
    
    
    override func createResultInstance(
        selfieFile: URL,
        documentFrontFile: URL,
        livenessFiles: [URL]?,
        documentBackFile: URL?,
        didSubmitJob: Bool
    ) -> DocumentVerificationResult {
        return DocumentVerificationResult(
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
