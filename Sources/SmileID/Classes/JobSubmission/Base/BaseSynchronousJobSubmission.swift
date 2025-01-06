//
//  BaseSynchronousJobSubmission.swift
//  Pods
//
//  Created by Japhet Ndhlovu on 12/5/24.
//

public class BaseSynchronousJobSubmission<ResultType: CaptureResult, ApiResponse>: BaseJobSubmission<ResultType> {
    // MARK: - Initialization

    override public init(jobId: String) {
        super.init(jobId: jobId)
    }

    // MARK: - Methods to Override

    /// Gets the API response for the job submission
    /// - Returns: Optional API response
    public func getApiResponse(authResponse _: AuthenticationResponse) async throws -> ApiResponse? {
        fatalError("Must be implemented by subclass")
    }

    /// Creates the synchronous result for the job submission
    /// - Parameter result: Optional API response
    /// - Returns: Success result object
    public func createSynchronousResult(result _: ApiResponse?) async throws -> SmileIDResult<ResultType>.Success<ResultType> {
        fatalError("Must be implemented by subclass")
    }

    // MARK: - Overridden Methods

    /// Executes the API submission process
    /// - Parameter offlineMode: If true, performs offline preparation
    /// - Returns: Result of the job submission
    override public func executeApiSubmission(offlineMode: Bool) async throws -> SmileIDResult<ResultType> {
        if offlineMode {
            try await handleOfflinePreparation()
        }

        do {
            let authResponse = try await executeAuthentication()
            let apiResponse = try await getApiResponse(authResponse: authResponse)
            let successResult = try await createSynchronousResult(result: apiResponse)
            return .success(successResult)
        } catch {
            return .error(error)
        }
    }

    /// Creates the success result for the job submission
    /// - Parameter didSubmit: Whether the job was submitted to the backend
    /// - Returns: Success result object
    override public func createSuccessResult(didSubmit: Bool) async throws -> SmileIDResult<ResultType>.Success<ResultType> {
        var apiResponse: ApiResponse? = nil
        if didSubmit {
            let authResponse = try await executeAuthentication()
            apiResponse = try await getApiResponse(authResponse: authResponse)
        }
        return try await createSynchronousResult(result: apiResponse)
    }
}
