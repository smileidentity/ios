//
//  BaseDocumentVerificationSubmission.swift
//  Pods
//
//  Created by Japhet Ndhlovu on 12/5/24.
//

public class BaseDocumentVerificationSubmission<ResultType: CaptureResult>: BaseJobSubmission<ResultType> {
    // MARK: - Properties

    private let userId: String
    private let jobType: JobType
    private let countryCode: String
    private let documentType: String?
    private let allowNewEnroll: Bool
    private let documentFrontFile: URL
    private let selfieFile: URL
    private let documentBackFile: URL?
    private let livenessFiles: [URL]?
    private let extraPartnerParams: [String: String]
    private let metadata: [Metadatum]?

    // MARK: - Initialization

    public init(
        jobId: String,
        userId: String,
        jobType: JobType,
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
        self.userId = userId
        self.jobType = jobType
        self.countryCode = countryCode
        self.documentType = documentType
        self.allowNewEnroll = allowNewEnroll
        self.documentFrontFile = documentFrontFile
        self.selfieFile = selfieFile
        self.documentBackFile = documentBackFile
        self.livenessFiles = livenessFiles
        self.extraPartnerParams = extraPartnerParams
        self.metadata = metadata
        super.init(jobId: jobId)
    }

    // MARK: - Overridden Methods

    override public func createAuthRequest() -> AuthenticationRequest {
        return AuthenticationRequest(
            jobType: jobType,
            enrollment: false,
            jobId: jobId,
            userId: userId,
            country: countryCode,
            idType: documentType
        )
    }

    override public func createPrepUploadRequest(authResponse: AuthenticationResponse? = nil) -> PrepUploadRequest {
        let partnerParams = authResponse?.partnerParams.copy(extras: extraPartnerParams)
            ?? PartnerParams(jobId: jobId, userId: userId, jobType: jobType, extras: extraPartnerParams)

        return PrepUploadRequest(
            partnerParams: partnerParams,
            allowNewEnroll: String(allowNewEnroll),
            metadata: metadata,
            timestamp: authResponse?.timestamp ?? "",
            signature: authResponse?.signature ?? ""
        )
    }

    override public func createUploadRequest(authResponse _: AuthenticationResponse?) -> UploadRequest {
        let frontImageInfo = documentFrontFile.asDocumentFrontImage()
        let backImageInfo = documentBackFile?.asDocumentBackImage()
        let selfieImageInfo = selfieFile.asSelfieImage()
        let livenessImageInfo = livenessFiles?.map { $0.asLivenessImage() } ?? []

        return UploadRequest(
            images: [frontImageInfo] +
                (backImageInfo.map { [$0] } ?? []) +
                [selfieImageInfo] +
                livenessImageInfo,
            idInfo: IdInfo(country: countryCode, idType: documentType)
        )
    }

    override public func createSuccessResult(didSubmit: Bool) async throws ->
        SmileIDResult<ResultType>.Success<ResultType> {
        let result = createResultInstance(selfieFile: selfieFile,
                                          documentFrontFile: documentFrontFile,
                                          livenessFiles: livenessFiles,
                                          documentBackFile: documentBackFile,
                                          didSubmitJob: didSubmit)
        return SmileIDResult.Success(result: result)
    }

    // MARK: - Abstract Methods

    /// Creates the result instance for the document verification submission
    /// - Parameters:
    ///   - selfieFile: The selfie file URL
    ///   - documentFrontFile: The document front file URL
    ///   - livenessFiles: Optional array of liveness file URLs
    ///   - documentBackFile: Optional document back file URL
    ///   - didSubmitJob: Whether the job was submitted
    /// - Returns: Result instance of type ResultType
    open func createResultInstance(
        selfieFile _: URL,
        documentFrontFile _: URL,
        livenessFiles _: [URL]?,
        documentBackFile _: URL?,
        didSubmitJob _: Bool
    ) -> ResultType {
        fatalError("Must be implemented by subclass")
    }
}

// MARK: - URL Extensions
