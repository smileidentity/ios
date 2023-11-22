import Combine
import Foundation

public protocol SmileIDServiceable {
    /// Returns a signature and timestamp that can be used to authenticate future requests. This is
    /// necessary only when using the authToken and *not* using the API key.
    func authenticate(request: AuthenticationRequest) -> AnyPublisher<AuthenticationResponse, Error>

    /// Used by Job Types that need to upload a file to the server. The response contains the URL
    /// that the file should eventually be uploaded to (via upload).
    func prepUpload(request: PrepUploadRequest) -> AnyPublisher<PrepUploadResponse, Error>

    /// Uploads files to S3. The URL should be the one returned by `prepUpload`.
    func upload(zip: Data, to url: String) -> AnyPublisher<UploadResponse, Error>

    /// Query the Identity Information of an individual using their ID number from a supported ID
    /// Type. Return the personal information of the individual found in the database of the ID
    /// authority. The final result is delivered to the url provided in the request's `callbackUrl`
    /// (which is required for this request)
    /// - Requires: The `callbackUrl` must be set on the `request`
    func doEnhancedKycAsync(
        request: EnhancedKycRequest
    ) -> AnyPublisher<EnhancedKycAsyncResponse, Error>
    

    /// Query the Identity Information of an individual using their ID number from a supported ID
    /// Type. Return the personal information of the individual found in the database of the ID authority.
    /// This will be done synchronously, and the result will be returned in the response. If the ID
    /// provider is unavailable, the response will be an error.
    func doEnhancedKyc(
        request: EnhancedKycRequest
    ) -> AnyPublisher<EnhancedKycResponse, Error>

    /// Fetches the status of a Job. This can be used to check if a Job is complete, and if so,
    /// whether it was successful.
    func getJobStatus<T: JobResult>(
        request: JobStatusRequest
    ) -> AnyPublisher<JobStatusResponse<T>, Error>

    /// Returns supported products and metadata
    func getServices() -> AnyPublisher<ServicesResponse, Error>

    /// Returns the ID types that are enabled for authenticated partner and which of those require
    /// consent
    func getProductsConfig(
        request: ProductsConfigRequest
    ) -> AnyPublisher<ProductsConfigResponse, Error>

    /// Gets supported documents and metadata for Document Verification
    func getValidDocuments(
        request: ProductsConfigRequest
    ) -> AnyPublisher<ValidDocumentsResponse, Error>

    /// Returns the different modes of getting the BVN OTP, either via sms or email
    func requestBvnTotpMode(request: BvnTotpRequest) -> AnyPublisher<BvnTotpResponse, Error>

    /// Returns the BVN OTP via the selected mode
    func requestBvnOtp(request: BvnTotpModeRequest) -> AnyPublisher<BvnTotpModeResponse, Error>

    /// Submits the BVN OTP for verification
    func submitBvnOtp(request: SubmitBvnTotpRequest) -> AnyPublisher<SubmitBvnTotpResponse, Error>
}

extension SmileIDServiceable {
    /// Polls the server for the status of a Job until it is complete. This should be called after
    /// the  Job has been submitted to the server. The returned flow will be updated with every job
    /// status response. The flow will complete when the job is complete, or the attempt limit is
    /// reached. If any exceptions occur, only the last one will be thrown. If there is a successful
    /// API response after an exception, the exception will be ignored.
    /// - Parameters:
    ///   - request: The JobStatus request to made
    ///   - interval: The time interval in seconds between each poll
    ///   - numAttempts: The maximum number of polls before ending the flow
    public func pollJobStatus<T: JobResult>(
        request: JobStatusRequest,
        interval: TimeInterval,
        numAttempts: Int
    ) -> AnyPublisher<JobStatusResponse<T>, Error> {

        var lastError: Error?
        var attemptCount = 0

        func makeRequest() -> AnyPublisher<JobStatusResponse<T>, Error> {
            attemptCount += 1

            return SmileID.api.getJobStatus(request: request)
                // swiftlint:disable force_cast
                .map { response in response as! JobStatusResponse<T> }
                // swiftlint:enable force_cast
                .flatMap { response -> AnyPublisher<JobStatusResponse<T>, Error> in
                    if response.jobComplete {
                        return Just(response).setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                    } else if attemptCount < numAttempts {
                        return makeRequest()
                    } else {
                        return Fail(error: SmileIDError.jobStatusTimeOut).eraseToAnyPublisher()
                    }
                }
                .catch { error -> AnyPublisher<JobStatusResponse<T>, Error> in
                    lastError = error
                    if attemptCount < numAttempts {
                        return makeRequest()
                    } else {
                        return Fail(error: lastError ?? error).eraseToAnyPublisher()
                    }
                }
                .eraseToAnyPublisher()
        }

        return makeRequest()
    }
}

public class SmileIDService: SmileIDServiceable, ServiceRunnable {
    @Injected var serviceClient: RestServiceClient
    typealias PathType = String

    public func authenticate(
        request: AuthenticationRequest
    ) -> AnyPublisher<AuthenticationResponse, Error> {
        post(to: "auth_smile", with: request)
    }

    public func prepUpload(request: PrepUploadRequest) -> AnyPublisher<PrepUploadResponse, Error> {
        post(to: "upload", with: request)
    }

    public func upload(zip: Data, to url: String) -> AnyPublisher<UploadResponse, Error> {
        upload(data: zip, to: url, with: .put)
    }

    public func doEnhancedKycAsync(
        request: EnhancedKycRequest
    ) -> AnyPublisher<EnhancedKycAsyncResponse, Error> {
        post(to: "async_id_verification", with: request)
    }
    
    public func doEnhancedKyc(
        request: EnhancedKycRequest
    ) -> AnyPublisher<EnhancedKycResponse, Error> {
        post(to: "id_verification", with: request)
    }

    public func getJobStatus<T>(
        request: JobStatusRequest
    ) -> AnyPublisher<JobStatusResponse<T>, Error> {
        post(to: "job_status", with: request)
    }

    public func getServices() -> AnyPublisher<ServicesResponse, Error> {
        get(to: "services")
    }

    public func getProductsConfig(
        request: ProductsConfigRequest
    ) -> AnyPublisher<ProductsConfigResponse, Error> {
        post(to: "products_config", with: request)
    }

    public func getValidDocuments(
        request: ProductsConfigRequest
    ) -> AnyPublisher<ValidDocumentsResponse, Error> {
        post(to: "valid_documents", with: request)
    }

    public func requestBvnTotpMode(
        request: BvnTotpRequest
    ) -> AnyPublisher<BvnTotpResponse, Error> {
        post(to: "totp_consent", with: request)
    }

    public func requestBvnOtp(
        request: BvnTotpModeRequest
    ) -> AnyPublisher<BvnTotpModeResponse, Error> {
        post(to: "totp_consent/mode", with: request)
    }

    public func submitBvnOtp(
        request: SubmitBvnTotpRequest
    ) -> AnyPublisher<SubmitBvnTotpResponse, Error> {
        post(to: "totp_consent/otp", with: request)
    }
}
