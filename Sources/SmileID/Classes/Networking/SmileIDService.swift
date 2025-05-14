import Foundation

public protocol SmileIDServiceable {
    /// Returns a signature and timestamp that can be used to authenticate future requests. This is
    /// necessary only when using the authToken and *not* using the API key.
    func authenticate(request: AuthenticationRequest) async throws -> AuthenticationResponse

    /// Used by Job Types that need to upload a file to the server. The response contains the URL
    /// that the file should eventually be uploaded to (via upload).
    func prepUpload(request: PrepUploadRequest) async throws -> PrepUploadResponse

    /// Uploads files to S3. The URL should be the one returned by `prepUpload`.
    @discardableResult func upload(zip: Data, to url: String) async throws -> Data

    /// Perform a synchronous SmartSelfie Enrollment. The response will include the final result of
    /// the enrollment.
    func doSmartSelfieEnrollment(
        signature: String,
        timestamp: String,
        selfieImage: MultipartBody,
        livenessImages: [MultipartBody],
        userId: String?,
        partnerParams: [String: String]?,
        callbackUrl: String?,
        sandboxResult: Int?,
        allowNewEnroll: Bool?,
        failureReason: FailureReason?
    ) async throws -> SmartSelfieResponse

    /// Perform a synchronous SmartSelfie Authentication. The response will include the final result
    /// of the authentication.
    func doSmartSelfieAuthentication(
        signature: String,
        timestamp: String,
        userId: String,
        selfieImage: MultipartBody,
        livenessImages: [MultipartBody],
        partnerParams: [String: String]?,
        callbackUrl: String?,
        sandboxResult: Int?,
        failureReason: FailureReason?
    ) async throws -> SmartSelfieResponse

    /// Query the Identity Information of an individual using their ID number from a supported ID
    /// Type. Return the personal information of the individual found in the database of the ID
    /// authority. The final result is delivered to the url provided in the request's `callbackUrl`
    /// (which is required for this request)
    /// - Requires: The `callbackUrl` must be set on the `request`
    func doEnhancedKycAsync(
        request: EnhancedKycRequest
    ) async throws -> EnhancedKycAsyncResponse
    /// Query the Identity Information of an individual using their ID number from a supported ID
    /// Type. Return the personal information of the individual found in the database of the ID authority.
    /// This will be done synchronously, and the result will be returned in the response. If the ID
    /// provider is unavailable, the response will be an error.
    func doEnhancedKyc(
        request: EnhancedKycRequest
    ) async throws -> EnhancedKycResponse

    /// Fetches the status of a Job. This can be used to check if a Job is complete, and if so,
    /// whether it was successful.
    func getJobStatus<T: JobResult>(
        request: JobStatusRequest
    ) async throws -> JobStatusResponse<T>

    /// Returns supported products and metadata
    func getServices() async throws -> ServicesResponse

    /// Returns the ID types that are enabled for authenticated partner and which of those require
    /// consent
    func getProductsConfig(
        request: ProductsConfigRequest
    ) async throws -> ProductsConfigResponse

    /// Gets supported documents and metadata for Document Verification
    func getValidDocuments(
        request: ProductsConfigRequest
    ) async throws -> ValidDocumentsResponse

    /// Returns the different modes of getting the BVN OTP, either via sms or email
    func requestBvnTotpMode(request: BvnTotpRequest) async throws -> BvnTotpResponse

    /// Returns the BVN OTP via the selected mode
    func requestBvnOtp(request: BvnTotpModeRequest) async throws -> BvnTotpModeResponse

    /// Submits the BVN OTP for verification
    func submitBvnOtp(request: SubmitBvnTotpRequest) async throws -> SubmitBvnTotpResponse
}

public extension SmileIDServiceable {
    /// Polls the server for the status of a Job until it is complete. This should be called after
    /// the  Job has been submitted to the server. The returned flow will be updated with every job
    /// status response. The flow will complete when the job is complete, or the attempt limit is
    /// reached. If any exceptions occur, only the last one will be thrown. If there is a successful
    /// API response after an exception, the exception will be ignored.
    /// - Parameters:
    ///   - request: The JobStatus request to made
    ///   - interval: The time interval in seconds between each poll
    ///   - numAttempts: The maximum number of polls before ending the flow
    func pollJobStatus<T: JobResult>(
        request: JobStatusRequest,
        interval: TimeInterval,
        numAttempts: Int
    ) -> AsyncThrowingStream<JobStatusResponse<T>, Error> {
        AsyncThrowingStream { continuation in
            Task {
                var latestError: Error?
                for _ in 0..<numAttempts {
                    do {
                        let response: JobStatusResponse<T> = try await SmileID.api.getJobStatus(request: request)
                        continuation.yield(response)
                        // Reset the error if the API response was successful
                        latestError = nil
                        if response.jobComplete {
                            break
                        }
                    } catch {
                        latestError = error
                    }
                    try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                }
                if let latestError = latestError {
                    continuation.finish(throwing: latestError)
                } else {
                    continuation.finish()
                }
            }
        }
    }

    /// Polls the server for the status of a SmartSelfie Job until it is complete. This should be called after
    /// the  Job has been submitted to the server. The returned flow will be updated with every job
    /// status response. The flow will complete when the job is complete, or the attempt limit is
    /// reached. If any exceptions occur, only the last one will be thrown. If there is a successful
    /// API response after an exception, the exception will be ignored.
    /// - Parameters:
    ///   - request: The JobStatus request to made
    ///   - interval: The time interval in seconds between each poll
    ///   - numAttempts: The maximum number of polls before ending the flow
    func pollSmartSelfieJobStatus(
        request: JobStatusRequest,
        interval: TimeInterval,
        numAttempts: Int
    ) async throws -> AsyncThrowingStream<SmartSelfieJobStatusResponse, Error> {
        return pollJobStatus(request: request, interval: interval, numAttempts: numAttempts)
    }

    /// Polls the server for the status of a Document Verification Job until it is complete. This should be called after
    /// the  Job has been submitted to the server. The returned flow will be updated with every job
    /// status response. The flow will complete when the job is complete, or the attempt limit is
    /// reached. If any exceptions occur, only the last one will be thrown. If there is a successful
    /// API response after an exception, the exception will be ignored.
    /// - Parameters:
    ///   - request: The JobStatus request to made
    ///   - interval: The time interval in seconds between each poll
    ///   - numAttempts: The maximum number of polls before ending the flow
    func pollDocumentVerificationJobStatus(
        request: JobStatusRequest,
        interval: TimeInterval,
        numAttempts: Int
    ) async throws -> AsyncThrowingStream<DocumentVerificationJobStatusResponse, Error> {
        return pollJobStatus(request: request, interval: interval, numAttempts: numAttempts)
    }

    /// Polls the server for the status of a Biometric KYC Job until it is complete. This should be called after
    /// the  Job has been submitted to the server. The returned flow will be updated with every job
    /// status response. The flow will complete when the job is complete, or the attempt limit is
    /// reached. If any exceptions occur, only the last one will be thrown. If there is a successful
    /// API response after an exception, the exception will be ignored.
    /// - Parameters:
    ///   - request: The JobStatus request to made
    ///   - interval: The time interval in seconds between each poll
    ///   - numAttempts: The maximum number of polls before ending the flow
    func pollBiometricKycJobStatus(
        request: JobStatusRequest,
        interval: TimeInterval,
        numAttempts: Int
    ) async throws -> AsyncThrowingStream<BiometricKycJobStatusResponse, Error> {
        return pollJobStatus(request: request, interval: interval, numAttempts: numAttempts)
    }

    /// Polls the server for the status of a Enhanced Document Verification Job until it is complete.
    ///  This should be called after the  Job has been submitted to the server. The returned flow will be
    ///  updated with every job status response.
    ///  The flow will complete when the job is complete, or the attempt limit is reached.
    ///  If any exceptions occur, only the last one will be thrown. If there is a successful
    /// API response after an exception, the exception will be ignored.
    /// - Parameters:
    ///   - request: The JobStatus request to made
    ///   - interval: The time interval in seconds between each poll
    ///   - numAttempts: The maximum number of polls before ending the flow
    func pollEnhancedDocumentVerificationJobStatus(
        request: JobStatusRequest,
        interval: TimeInterval,
        numAttempts: Int
    ) async throws -> AsyncThrowingStream<EnhancedDocumentVerificationJobStatusResponse, Error> {
        return pollJobStatus(request: request, interval: interval, numAttempts: numAttempts)
    }
}

public class SmileIDService: SmileIDServiceable, ServiceRunnable {
    @Injected var serviceClient: RestServiceClient
    @Injected var metadata: Metadata
    typealias PathType = String

    public func authenticate(
        request: AuthenticationRequest
    ) async throws -> AuthenticationResponse {
        try await post(to: "auth_smile", with: request)
    }

    public func prepUpload(request: PrepUploadRequest) async throws -> PrepUploadResponse {
        try await post(to: "upload", with: request)
    }

    public func doSmartSelfieEnrollment(
        signature: String,
        timestamp: String,
        selfieImage: MultipartBody,
        livenessImages: [MultipartBody],
        userId: String? = nil,
        partnerParams: [String: String]? = nil,
        callbackUrl: String? = SmileID.callbackUrl,
        sandboxResult: Int? = nil,
        allowNewEnroll: Bool? = nil,
        failureReason: FailureReason? = nil
    ) async throws -> SmartSelfieResponse {
        try await multipart(
            to: "/v2/smart-selfie-enroll",
            signature: signature,
            timestamp: timestamp,
            selfieImage: selfieImage,
            livenessImages: livenessImages,
            userId: userId,
            partnerParams: partnerParams,
            callbackUrl: callbackUrl,
            sandboxResult: sandboxResult,
            allowNewEnroll: allowNewEnroll,
            failureReason: failureReason
        )
    }

    public func doSmartSelfieAuthentication(
        signature: String,
        timestamp: String,
        userId: String,
        selfieImage: MultipartBody,
        livenessImages: [MultipartBody],
        partnerParams: [String: String]? = nil,
        callbackUrl: String? = SmileID.callbackUrl,
        sandboxResult: Int? = nil,
        failureReason: FailureReason? = nil
    ) async throws -> SmartSelfieResponse {
        try await multipart(
            to: "/v2/smart-selfie-authentication",
            signature: signature,
            timestamp: timestamp,
            selfieImage: selfieImage,
            livenessImages: livenessImages,
            userId: userId,
            partnerParams: partnerParams,
            callbackUrl: callbackUrl,
            sandboxResult: sandboxResult,
            failureReason: failureReason
        )
    }

    public func upload(zip: Data, to url: String) async throws -> Data {
        try await upload(data: zip, to: url, with: .put)
    }

    public func doEnhancedKycAsync(
        request: EnhancedKycRequest
    ) async throws -> EnhancedKycAsyncResponse {
        try await post(to: "async_id_verification", with: request)
    }

    public func doEnhancedKyc(
        request: EnhancedKycRequest
    ) async throws -> EnhancedKycResponse {
        try await post(to: "id_verification", with: request)
    }

    public func getJobStatus<T>(
        request: JobStatusRequest
    ) async throws -> JobStatusResponse<T> {
        try await post(to: "job_status", with: request)
    }

    public func getServices() async throws -> ServicesResponse {
        try await get(to: "services")
    }

    public func getProductsConfig(
        request: ProductsConfigRequest
    ) async throws -> ProductsConfigResponse {
        try await post(to: "products_config", with: request)
    }

    public func getValidDocuments(
        request: ProductsConfigRequest
    ) async throws -> ValidDocumentsResponse {
        try await post(to: "valid_documents", with: request)
    }

    public func requestBvnTotpMode(
        request: BvnTotpRequest
    ) async throws -> BvnTotpResponse {
        try await post(to: "totp_consent", with: request)
    }

    public func requestBvnOtp(
        request: BvnTotpModeRequest
    ) async throws -> BvnTotpModeResponse {
        try await post(to: "totp_consent/mode", with: request)
    }

    public func submitBvnOtp(
        request: SubmitBvnTotpRequest
    ) async throws -> SubmitBvnTotpResponse {
        try await post(to: "totp_consent/otp", with: request)
    }
}
