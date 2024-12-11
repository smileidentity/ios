//
//  SelfieSubmission.swift
//  Pods
//
//  Created by Japhet Ndhlovu on 12/5/24.
//

public class SelfieSubmission: BaseSynchronousJobSubmission<SmartSelfieResult, SmartSelfieResponse> {
    // MARK: - Properties
    
    private let isEnroll: Bool
    private let userId: String
    private let allowNewEnroll: Bool
    private let selfieFile: URL
    private let livenessFiles: [URL]
    private let extraPartnerParams: [String: String]
    private let metadata: Metadata
    
    // MARK: - Initialization
    
    public init(
        isEnroll: Bool,
        userId: String,
        jobId: String,
        allowNewEnroll: Bool,
        selfieFile: URL,
        livenessFiles: [URL],
        extraPartnerParams: [String: String],
        metadata: Metadata
    ) {
        self.isEnroll = isEnroll
        self.userId = userId
        self.allowNewEnroll = allowNewEnroll
        self.selfieFile = selfieFile
        self.livenessFiles = livenessFiles
        self.extraPartnerParams = extraPartnerParams
        self.metadata = metadata
        super.init(jobId: jobId)
    }
    
    // MARK: - Overridden Methods
    
    public override func createAuthRequest() -> AuthenticationRequest {
        return AuthenticationRequest(
            jobType: isEnroll ? .smartSelfieEnrollment : .smartSelfieAuthentication,
            enrollment: isEnroll,
            jobId: jobId,
            userId: userId
        )
    }
    
    public override func createPrepUploadRequest(authResponse: AuthenticationResponse? = nil) -> PrepUploadRequest {
        return PrepUploadRequest(
            partnerParams: PartnerParams(
                jobId: jobId,
                userId: userId,
                jobType: isEnroll ? .smartSelfieEnrollment : .smartSelfieAuthentication,
                extras: extraPartnerParams
            ),
            allowNewEnroll: String(allowNewEnroll),
            metadata: metadata.items,
            timestamp: authResponse?.timestamp ?? "",
            signature: authResponse?.signature ?? ""
        )
    }
    
    public override func createUploadRequest(authResponse: AuthenticationResponse?) -> UploadRequest {
        return UploadRequest(
            images: [selfieFile.asSelfieImage()] + livenessFiles.map { url in
                url.asLivenessImage()
            }
        )
    }
    
    public override func getApiResponse(authResponse:AuthenticationResponse) async throws -> SmartSelfieResponse? {
        var smartSelfieImage: MultipartBody?
        var smartSelfieLivenessImages = [MultipartBody]()
        if let selfie = try? Data(contentsOf: selfieFile), let media = MultipartBody(
            withImage: selfie,
            forKey: selfieFile.lastPathComponent,
            forName: selfieFile.lastPathComponent
        ) {
            smartSelfieImage = media
        }
        if !livenessFiles.isEmpty {
            let livenessImageInfos = livenessFiles.compactMap { liveness -> MultipartBody? in
                if let data = try? Data(contentsOf: liveness) {
                    return MultipartBody(
                        withImage: data,
                        forKey: liveness.lastPathComponent,
                        forName: liveness.lastPathComponent
                    )
                }
                return nil
            }
            
            smartSelfieLivenessImages.append(contentsOf: livenessImageInfos.compactMap { $0 })
        }
        guard let smartSelfieImage = smartSelfieImage,
              !smartSelfieLivenessImages.isEmpty
        else {
            throw SmileIDError.unknown("Selfie submission failed")
        }
        
        let response = if isEnroll {
            try await SmileID.api.doSmartSelfieEnrollment(
                signature: authResponse.signature,
                timestamp: authResponse.timestamp,
                selfieImage: smartSelfieImage,
                livenessImages: smartSelfieLivenessImages,
                userId: userId,
                partnerParams: extraPartnerParams,
                callbackUrl: SmileID.callbackUrl,
                sandboxResult: nil,
                allowNewEnroll: allowNewEnroll,
                metadata: metadata
            )
        } else {
            try await SmileID.api.doSmartSelfieAuthentication(
                signature: authResponse.signature,
                timestamp: authResponse.timestamp,
                userId: userId,
                selfieImage: smartSelfieImage,
                livenessImages: smartSelfieLivenessImages,
                partnerParams: extraPartnerParams,
                callbackUrl: SmileID.callbackUrl,
                sandboxResult: nil,
                metadata: metadata
            )
        }
        return response
    }
    
    public override func createSynchronousResult(result: SmartSelfieResponse?) async throws -> SmileIDResult<SmartSelfieResult>.Success<SmartSelfieResult> {
        // Move files from unsubmitted to submitted directories
        var selfieFileResult = self.selfieFile
        var livenessImagesResult = self.livenessFiles
        
        do {
            if let result = result{
                try LocalStorage.moveToSubmittedJobs(jobId: self.jobId)
                guard let selfieFileResult = try LocalStorage.getFileByType(
                    jobId: jobId,
                    fileType: FileType.selfie,
                    submitted: true
                ) else{
                    throw SmileIDError.unknown("Selfie file not found")
                }
                livenessImagesResult = try LocalStorage.getFilesByType(
                    jobId: jobId,
                    fileType: FileType.liveness,
                    submitted: true
                ) ?? []
            }
        } catch {
            print("Error moving job to submitted directory: \(error)")
            throw error
        }
        
        let captureResult = SelfieCaptureResult(
            selfieImage: selfieFileResult,
            livenessImages: livenessImagesResult
        )
        
        let finalResult = SmartSelfieResult(
            captureData: captureResult,
            didSubmitJob: true,
            apiResponse: result
        )
        
        return SmileIDResult.Success(result: finalResult)
    }
}
