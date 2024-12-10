//
//  BaseJobSubmission.swift
//  Pods
//
//  Created by Japhet Ndhlovu on 12/5/24.
//

public class BaseJobSubmission<ResultType: CaptureResult> {
    // MARK: - Properties
    
    public let jobId: String
    
    // MARK: - Initialization
    
    public init(jobId: String) {
        self.jobId = jobId
    }
    
    // MARK: - Methods to Override
    
    /// Creates the authentication request for the job submission
    /// - Returns: Authentication request object
    public func createAuthRequest() -> AuthenticationRequest {
        fatalError("Must be implemented by subclass")
    }
    
    /// Creates the prep upload request for the job submission
    /// - Parameter authResponse: Optional authentication response from previous step
    /// - Returns: Prep upload request object
    public func createPrepUploadRequest(authResponse: AuthenticationResponse? = nil) -> PrepUploadRequest {
        fatalError("Must be implemented by subclass")
    }
    
    /// Creates the upload request for the job submission
    /// - Parameter authResponse: Optional authentication response from previous step
    /// - Returns: Upload request object
    public func createUploadRequest(authResponse: AuthenticationResponse?) -> UploadRequest {
        fatalError("Must be implemented by subclass")
    }
    
    /// Creates the success result for the job submission
    /// - Parameter didSubmit: Whether the job was submitted to the backend
    /// - Returns: Success result object
    public func createSuccessResult(didSubmit: Bool) async throws -> SmileIDResult<ResultType>.Success<ResultType> {
        fatalError("Must be implemented by subclass")
    }
    
    // MARK: - Public Methods
    
    /// Executes the job submission process
    /// - Parameters:
    ///   - skipApiSubmission: If true, skips the API submission
    ///   - offlineMode: If true, performs offline preparation
    /// - Returns: Result of the job submission
    public func executeSubmission(
        skipApiSubmission: Bool = false,
        offlineMode: Bool = false
    ) async -> SmileIDResult<ResultType> {
        do {
            if skipApiSubmission {
                let successResult = try await createSuccessResult(didSubmit: false)
                return .success(successResult)
            } else {
                return try await executeApiSubmission(offlineMode: offlineMode)
            }
        } catch {
            return .error(error)
        }
    }
    
    /// Handles offline preparation logic
    /// Override this method to implement custom offline preparation
    public func handleOfflinePreparation() async throws {
        let authRequest = createAuthRequest()
        try  LocalStorage.createAuthenticationRequestFile(jobId: jobId, authentationRequest: authRequest)
        try LocalStorage.createPrepUploadFile(
            jobId: jobId,
            prepUpload: createPrepUploadRequest()
        )
    }
    
    // MARK: - Private Methods
    
    func executeApiSubmission(offlineMode: Bool) async throws -> SmileIDResult<ResultType> {
        if offlineMode {
            try await handleOfflinePreparation()
        }
        
        do {
            let authResponse = try await executeAuthentication()
            let prepUploadResponse = try await executePrepUpload(authResponse: authResponse)
            try await executeUpload(authResponse: authResponse, prepUploadResponse: prepUploadResponse)
            let successResult = try await createSuccessResult(didSubmit: true)
            return .success(successResult)
        } catch {
            return .error(error)
        }
    }
    
    func executeAuthentication() async throws -> AuthenticationResponse {
        do {
            return try await SmileID.api.authenticate(request: createAuthRequest())
        } catch let error as SmileIDError {
            throw error
        } catch {
            throw error
        }
    }
    
    private func executePrepUpload(
        authResponse: AuthenticationResponse?
    ) async throws -> PrepUploadResponse {
        let prepUploadRequest = createPrepUploadRequest(authResponse: authResponse)
        return try await executePrepUploadWithRetry(prepUploadRequest: prepUploadRequest)
    }
    
    private func executePrepUploadWithRetry(
        prepUploadRequest: PrepUploadRequest,
        isRetry: Bool = false
    ) async throws -> PrepUploadResponse {
        do {
            return try await SmileID.api.prepUpload(request: prepUploadRequest)
        } catch let error as SmileIDError {
            if !isRetry && error.localizedDescription == SmileErrorConstants.RETRY {
                var retryRequest = prepUploadRequest
                retryRequest.retry = "true"
                return try await executePrepUploadWithRetry(prepUploadRequest: retryRequest, isRetry: true)
            } else {
                throw error
            }
        }
    }
    
    private func executeUpload(
        authResponse: AuthenticationResponse?,
        prepUploadResponse: PrepUploadResponse
    ) async throws {
        do {
            let uploadRequest = createUploadRequest(authResponse: authResponse)
            let allFiles: [URL]
            do {
                let livenessFiles = try LocalStorage.getFilesByType(jobId: jobId, fileType: .liveness) ?? []
                let additionalFiles = try [
                    LocalStorage.getFileByType(jobId: jobId, fileType: .selfie),
                    LocalStorage.getFileByType(jobId: jobId, fileType: .documentFront),
                    LocalStorage.getFileByType(jobId: jobId, fileType: .documentBack),
                    LocalStorage.getInfoJsonFile(jobId: jobId)
                ].compactMap { $0 }
                allFiles = livenessFiles + additionalFiles
            } catch {
                throw error
            }
            let zipData = try LocalStorage.zipFiles(at: allFiles)
            try await SmileID.api.upload(zip: zipData, to: prepUploadResponse.uploadUrl)
        } catch {
            throw error
        }
    }
    
    // MARK: - Constants
    
}

private enum SmileErrorConstants {
    static let RETRY = "2215"
}
