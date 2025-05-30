import SwiftUI

protocol SelfieSubmissionDelegate: AnyObject {
    func submissionDidSucceed(_ apiResponse: SmartSelfieResponse)
    func submissionDidFail(
        with error: Error,
        errorMessage: String?,
        errorMessageRes: String?,
        updatedSelfieImageUrl: URL?,
        updatedLivenessImages: [URL]
    )
}

final class SelfieSubmissionManager {
    // MARK: - Properties
    private let userId: String
    private let isEnroll: Bool
    private let numLivenessImages: Int
    private let allowNewEnroll: Bool
    private var selfieImageUrl: URL?
    private var livenessImages: [URL]
    private var extraPartnerParams: [String: String]
    private var metadata: [Metadatum]

    weak var delegate: SelfieSubmissionDelegate?

    // MARK: - Initializer
    init(
        userId: String,
        isEnroll: Bool,
        numLivenessImages: Int,
        allowNewEnroll: Bool,
        selfieImageUrl: URL?,
        livenessImages: [URL],
        extraPartnerParams: [String: String],
        metadata: [Metadatum]
    ) {
        self.userId = userId
        self.isEnroll = isEnroll
        self.numLivenessImages = numLivenessImages
        self.allowNewEnroll = allowNewEnroll
        self.selfieImageUrl = selfieImageUrl
        self.livenessImages = livenessImages
        self.extraPartnerParams = extraPartnerParams
        self.metadata = metadata
    }

    func submitJob(failureReason: FailureReason? = nil) async throws {
        do {
            // Validate that the necessary selfie data is present
            try validateImages()

            // Determine the type of job (enrollment or authentication)
            let jobType = determineJobType()
            // Create an authentication request based on the job type
            let authRequest = createAuthRequest(jobType: jobType)

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
        return isEnroll ? JobType.smartSelfieEnrollment : JobType.smartSelfieAuthentication
    }

    private func createAuthRequest(jobType: JobType) -> AuthenticationRequest {
        return AuthenticationRequest(
            jobType: jobType,
            enrollment: isEnroll,
            userId: userId
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
            forName: fileURL.lastPathComponent
        )
    }

    private func submitJobRequest(
        authResponse: AuthenticationResponse,
        smartSelfieImage: MultipartBody,
        smartSelfieLivenessImages: [MultipartBody],
        failureReason: FailureReason?
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
                    failureReason: failureReason
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
                    failureReason: failureReason
                )
        }
    }

    private func handleJobSubmissionFailure(_ smileIDError: SmileIDError) {
        let (errorMessageRes, errorMessage) = toErrorMessage(error: smileIDError)
        self.delegate?
            .submissionDidFail(
                with: smileIDError,
                errorMessage: errorMessage,
                errorMessageRes: errorMessageRes,
                updatedSelfieImageUrl: selfieImageUrl,
                updatedLivenessImages: livenessImages
            )
    }
}
