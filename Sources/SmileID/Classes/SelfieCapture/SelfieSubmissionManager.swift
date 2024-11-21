import SwiftUI

protocol SelfieSubmissionDelegate: AnyObject {
    func submissionDidSucceed(_ apiResponse: SmartSelfieResponse)
    func submissionDidFail(with error: Error, errorMessage: String?, errorMessageRes: String?)
}

final class SelfieSubmissionManager {
    // MARK: - Properties
    private let selfieCaptureConfig: SelfieCaptureConfig
    private let numLivenessImages: Int
    private var selfieImageUrl: URL?
    private var livenessImages: [URL]
    private let localMetadata: LocalMetadata

    weak var delegate: SelfieSubmissionDelegate?

    // MARK: - Initializer
    init(
        selfieCaptureConfig: SelfieCaptureConfig,
        numLivenessImages: Int,
        selfieImageUrl: URL?,
        livenessImages: [URL],
        localMetadata: LocalMetadata
    ) {
        self.selfieCaptureConfig = selfieCaptureConfig
        self.numLivenessImages = numLivenessImages
        self.selfieImageUrl = selfieImageUrl
        self.livenessImages = livenessImages
        self.localMetadata = localMetadata
    }

    func submitJob(failureReason: FailureReason? = nil) async throws {
        do {
            // Validate that the necessary selfie data is present
            try validateImages()

            // Determine the type of job (enrollment or authentication)
            let jobType = determineJobType()
            // Create an authentication request based on the job type
            let authRequest = createAuthRequest(jobType: jobType)

            // Save the job locally if offline mode is allowed
            if SmileID.allowOfflineMode {
                try saveOfflineMode(jobType: jobType)
            }

            // Authenticate the request with the API
            let authResponse = try await SmileID.api.authenticate(request: authRequest)

            // Prepare the images for submission
            let (smartSelfieImage, smartSelfieLivenessImages) = try prepareImagesForSubmission()

            // Submit the job data to the API
            let response = try await submitJobRequest(
                authResponse: authResponse,
                smartSelfieImage: smartSelfieImage,
                smartSelfieLivenessImages: smartSelfieLivenessImages,
                failureReason: failureReason
            )

            // Update local storage after successful submission
            try updateLocalStorageAfterSuccess()

            // Send out api response after successful submission
            self.delegate?.submissionDidSucceed(response)
        } catch let error as SmileIDError {
            handleJobSubmissionFailure(error)
        }
    }

    private func validateImages() throws {
        guard selfieImageUrl != nil,
                livenessImages.count == numLivenessImages else {
            throw SmileIDError.unknown("Selfie capture failed")
        }
    }

    private func determineJobType() -> JobType {
        return selfieCaptureConfig.isEnroll ? JobType.smartSelfieEnrollment : JobType.smartSelfieAuthentication
    }

    private func createAuthRequest(jobType: JobType) -> AuthenticationRequest {
        return AuthenticationRequest(
            jobType: jobType,
            enrollment: selfieCaptureConfig.isEnroll,
            jobId: selfieCaptureConfig.jobId,
            userId: selfieCaptureConfig.userId
        )
    }

    private func saveOfflineMode(jobType: JobType) throws {
        try LocalStorage.saveOfflineJob(
            jobId: selfieCaptureConfig.jobId,
            userId: selfieCaptureConfig.userId,
            jobType: jobType,
            enrollment: selfieCaptureConfig.isEnroll,
            allowNewEnroll: selfieCaptureConfig.allowNewEnroll,
            localMetadata: localMetadata,
            partnerParams: selfieCaptureConfig.extraPartnerParams
        )
    }

    private func prepareImagesForSubmission() throws -> (MultipartBody, [MultipartBody]) {
        guard let smartSelfieImage = createMultipartBody(from: selfieImageUrl) else {
            throw SmileIDError.fileNotFound("Could not create multipart body for file")
        }

        let smartSelfieLivenessImages = livenessImages.compactMap {
            createMultipartBody(from: $0)
        }
        guard smartSelfieLivenessImages.count == numLivenessImages else {
            throw SmileIDError.unknown("Liveness image count mismatch")
        }

        return (smartSelfieImage, smartSelfieLivenessImages)
    }

    private func createMultipartBody(from fileURL: URL?) -> MultipartBody? {
        guard let fileURL = fileURL,
            let imageData = try? Data(contentsOf: fileURL)
        else {
            return nil
        }
        return MultipartBody(
            withImage: imageData,
            forKey: fileURL.lastPathComponent,
            forName: fileURL.lastPathComponent
        )
    }

    private func submitJobRequest(
        authResponse: AuthenticationResponse,
        smartSelfieImage: MultipartBody,
        smartSelfieLivenessImages: [MultipartBody],
        failureReason: FailureReason?
    ) async throws -> SmartSelfieResponse {
        if selfieCaptureConfig.isEnroll {
            return try await SmileID.api
                .doSmartSelfieEnrollment(
                    signature: authResponse.signature,
                    timestamp: authResponse.timestamp,
                    selfieImage: smartSelfieImage,
                    livenessImages: smartSelfieLivenessImages,
                    userId: selfieCaptureConfig.userId,
                    partnerParams: selfieCaptureConfig.extraPartnerParams,
                    callbackUrl: SmileID.callbackUrl,
                    sandboxResult: nil,
                    allowNewEnroll: selfieCaptureConfig.allowNewEnroll,
                    failureReason: failureReason,
                    metadata: localMetadata.metadata
                )
        } else {
            return try await SmileID.api
                .doSmartSelfieAuthentication(
                    signature: authResponse.signature,
                    timestamp: authResponse.timestamp,
                    userId: selfieCaptureConfig.userId,
                    selfieImage: smartSelfieImage,
                    livenessImages: smartSelfieLivenessImages,
                    partnerParams: selfieCaptureConfig.extraPartnerParams,
                    callbackUrl: SmileID.callbackUrl,
                    sandboxResult: nil,
                    failureReason: failureReason,
                    metadata: localMetadata.metadata
                )
        }
    }

    private func updateLocalStorageAfterSuccess() throws {
        // Move the job to the submitted jobs directory for record-keeping
        try LocalStorage.moveToSubmittedJobs(jobId: selfieCaptureConfig.jobId)

        // Update the references to the submitted selfie and liveness images
        self.selfieImageUrl = try LocalStorage.getFileByType(
            jobId: selfieCaptureConfig.jobId,
            fileType: FileType.selfie,
            submitted: true
        )
        self.livenessImages =
            try LocalStorage.getFilesByType(
                jobId: selfieCaptureConfig.jobId,
                fileType: FileType.liveness,
                submitted: true
            ) ?? []
    }

    private func handleJobSubmissionFailure(_ smileIDError: SmileIDError) {
        do {
            let didMove = try LocalStorage.handleOfflineJobFailure(
                jobId: selfieCaptureConfig.jobId,
                error: smileIDError
            )
            if didMove {
                self.selfieImageUrl = try LocalStorage.getFileByType(
                    jobId: selfieCaptureConfig.jobId,
                    fileType: .selfie,
                    submitted: true
                )
                self.livenessImages =
                try LocalStorage.getFilesByType(
                    jobId: selfieCaptureConfig.jobId,
                    fileType: .liveness,
                    submitted: true
                ) ?? []
            }
        } catch {
            let (errorMessageRes, errorMessage) = toErrorMessage(error: smileIDError)
            self.delegate?
                .submissionDidFail(
                    with: error,
                    errorMessage: errorMessageRes,
                    errorMessageRes: errorMessage
                )
            return
        }

        if SmileID.allowOfflineMode, SmileIDError.isNetworkFailure(error: smileIDError) {
            self.delegate?.submissionDidFail(with: smileIDError, errorMessage: nil, errorMessageRes: "Offline.Message")
        } else {
            let (errorMessageRes, errorMessage) = toErrorMessage(error: smileIDError)
            self.delegate?
                .submissionDidFail(
                    with: smileIDError,
                    errorMessage: errorMessage,
                    errorMessageRes: errorMessageRes
                )
        }
    }
}
