//
//  BiometricKYCSubmission.swift
//  Pods
//
//  Created by Japhet Ndhlovu on 12/5/24.
//

public class BiometricKYCSubmission: BaseJobSubmission<BiometricKycResult> {
    // MARK: - Properties

    private let userId: String
    private let allowNewEnroll: Bool
    private let livenessFiles: [URL]?
    private let selfieFile: URL
    private let idInfo: IdInfo
    private let extraPartnerParams: [String: String]
    private let metadata: Metadata

    // MARK: - Initialization

    public init(
        userId: String,
        jobId: String,
        allowNewEnroll: Bool,
        livenessFiles: [URL]?,
        selfieFile: URL,
        idInfo: IdInfo,
        extraPartnerParams: [String: String],
        metadata: Metadata
    ) {
        self.userId = userId
        self.allowNewEnroll = allowNewEnroll
        self.livenessFiles = livenessFiles
        self.selfieFile = selfieFile
        self.idInfo = idInfo
        self.extraPartnerParams = extraPartnerParams
        self.metadata = metadata
        super.init(jobId: jobId)
    }

    // MARK: - BaseJobSubmission Overrides

    override public func createAuthRequest() -> AuthenticationRequest {
        return AuthenticationRequest(
            jobType: .biometricKyc,
            enrollment: false,
            jobId: jobId,
            userId: userId,
            country: idInfo.country,
            idType: idInfo.idType
        )
    }

    override public func createPrepUploadRequest(authResponse: AuthenticationResponse? = nil) -> PrepUploadRequest {
        let partnerParams = authResponse?.partnerParams.copy(extras: extraPartnerParams) ??
            PartnerParams(
                jobId: jobId,
                userId: userId,
                jobType: .biometricKyc,
                extras: extraPartnerParams
            )

        return PrepUploadRequest(
            partnerParams: partnerParams,
            allowNewEnroll: String(allowNewEnroll),
            metadata: metadata.items,
            timestamp: authResponse?.timestamp ?? "",
            signature: authResponse?.signature ?? ""
        )
    }

    override public func createUploadRequest(authResponse _: AuthenticationResponse?) -> UploadRequest {
        let selfieImageInfo = selfieFile.asSelfieImage()
        let livenessImageInfo = livenessFiles?.map { $0.asLivenessImage() } ?? []

        return UploadRequest(
            images: [selfieImageInfo] + livenessImageInfo,
            idInfo: idInfo.copy(entered: true)
        )
    }

    override public func createSuccessResult(didSubmit: Bool) async throws -> SmileIDResult<BiometricKycResult>.Success<BiometricKycResult> {
        let result = BiometricKycResult(
            captureData: SelfieCaptureResult(
                selfieImage: selfieFile,
                livenessImages: livenessFiles
            ),
            didSubmitJob: didSubmit
        )

        return SmileIDResult.Success(result: result)
    }
}
