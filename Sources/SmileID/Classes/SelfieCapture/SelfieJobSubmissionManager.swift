import SwiftUI

protocol SelfieJobSubmissionDelegate: AnyObject {
    func submissionDidSucceed(_ apiResponse: SmartSelfieResponse)
    func submissionDidFail(with error: Error, errorMessage: String?, errorMessageRes: String?)
}

final class SelfieJobSubmissionManager {
    // MARK: - Properties
    private let userId: String
    private let jobId: String
    private let isEnroll: Bool
    private let numLivenessImages: Int
    private let allowNewEnroll: Bool
    private var selfieImage: URL?
    private var livenessImages: [URL]
    private var extraPartnerParams: [String: String]
    private let localMetadata: LocalMetadata

    weak var delegate: SelfieJobSubmissionDelegate?

    // MARK: - Initializer
    init(
        userId: String,
        jobId: String,
        isEnroll: Bool,
        numLivenessImages: Int,
        allowNewEnroll: Bool,
        selfieImage: URL?,
        livenessImages: [URL],
        extraPartnerParams: [String: String],
        localMetadata: LocalMetadata
    ) {
        self.userId = userId
        self.jobId = jobId
        self.isEnroll = isEnroll
        self.numLivenessImages = numLivenessImages
        self.allowNewEnroll = allowNewEnroll
        self.selfieImage = selfieImage
        self.livenessImages = livenessImages
        self.extraPartnerParams = extraPartnerParams
        self.localMetadata = localMetadata
    }

    func submitJob(forcedFailure: Bool = false) async throws {
        do {
            // Validate that the necessary selfie data is present
            try validateImages(forcedFailure: forcedFailure)

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
                forcedFailure: forcedFailure
            )

            // Update local storage after successful submission
            try updateLocalStorageAfterSuccess()

            // Send out api response after successful submission
            self.delegate?.submissionDidSucceed(response)
        } catch let error as SmileIDError {
            handleJobSubmissionFailure(error: error)
        }
    }

    private func validateImages(forcedFailure: Bool) throws {
        if forcedFailure {
            guard selfieImage != nil else {
                throw SmileIDError.unknown("Selfie capture failed")
            }
        } else {
            guard selfieImage != nil, livenessImages.count == numLivenessImages else {
                throw SmileIDError.unknown("Selfie capture failed")
            }
        }
    }

    private func determineJobType() -> JobType {
        return isEnroll ? JobType.smartSelfieEnrollment : JobType.smartSelfieAuthentication
    }

    private func createAuthRequest(jobType: JobType) -> AuthenticationRequest {
        return AuthenticationRequest(
            jobType: jobType,
            enrollment: isEnroll,
            jobId: jobId,
            userId: userId
        )
    }

    private func saveOfflineMode(jobType: JobType) throws {
        try LocalStorage.saveOfflineJob(
            jobId: jobId,
            userId: userId,
            jobType: jobType,
            enrollment: isEnroll,
            allowNewEnroll: allowNewEnroll,
            localMetadata: localMetadata,
            partnerParams: extraPartnerParams
        )
    }

    private func prepareImagesForSubmission() throws -> (MultipartBody, [MultipartBody]) {
        guard let smartSelfieImage = createMultipartBody(from: selfieImage) else {
            throw SmileIDError.unknown("Failed to process selfie image")
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
        else { return nil }
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
        forcedFailure: Bool
    ) async throws -> SmartSelfieResponse {
        if isEnroll {
            return try await SmileID.api
                .doSmartSelfieEnrollment(
                    signature: authResponse.signature,
                    timestamp: authResponse.timestamp,
                    selfieImage: smartSelfieImage,
                    livenessImages: smartSelfieLivenessImages,
                    userId: userId,
                    partnerParams: extraPartnerParams,
                    callbackUrl: SmileID.callbackUrl,
                    sandboxResult: nil,
                    allowNewEnroll: allowNewEnroll,
                    failureReason: forcedFailure ? .activeLivenessTimedOut : nil,
                    metadata: localMetadata.metadata
                )
        } else {
            return try await SmileID.api
                .doSmartSelfieAuthentication(
                    signature: authResponse.signature,
                    timestamp: authResponse.timestamp,
                    userId: userId,
                    selfieImage: smartSelfieImage,
                    livenessImages: smartSelfieLivenessImages,
                    partnerParams: extraPartnerParams,
                    callbackUrl: SmileID.callbackUrl,
                    sandboxResult: nil,
                    failureReason: forcedFailure ? .activeLivenessTimedOut : nil,
                    metadata: localMetadata.metadata
                )
        }
    }

    private func updateLocalStorageAfterSuccess() throws {
        // Move the job to the submitted jobs directory for record-keeping
        try LocalStorage.moveToSubmittedJobs(jobId: self.jobId)

        // Update the references to the submitted selfie and liveness images
        self.selfieImage = try LocalStorage.getFileByType(
            jobId: jobId,
            fileType: FileType.selfie,
            submitted: true
        )
        self.livenessImages =
            try LocalStorage.getFilesByType(
                jobId: jobId,
                fileType: FileType.liveness,
                submitted: true
            ) ?? []
    }

    private func handleJobSubmissionFailure(error: SmileIDError) {
        do {
            let didMove = try LocalStorage.handleOfflineJobFailure(jobId: self.jobId, error: error)
            if didMove {
                self.selfieImage = try LocalStorage.getFileByType(jobId: jobId, fileType: .selfie, submitted: true)
                self.livenessImages =
                    try LocalStorage.getFilesByType(jobId: jobId, fileType: .liveness, submitted: true) ?? []
            }
        } catch {
            self.delegate?.submissionDidFail(with: error, errorMessage: nil, errorMessageRes: nil)
            return
        }

        if SmileID.allowOfflineMode, LocalStorage.isNetworkFailure(error: error) {
            self.delegate?.submissionDidFail(with: error, errorMessage: nil, errorMessageRes: "Offline.Message")
        } else {
            let (errorMessageRes, errorMessage) = toErrorMessage(error: error)
            self.delegate?.submissionDidFail(with: error, errorMessage: errorMessage, errorMessageRes: errorMessageRes)
        }
    }
}
