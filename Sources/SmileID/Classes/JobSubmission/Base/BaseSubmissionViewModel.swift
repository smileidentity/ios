//
//  BaseSubmissionViewModel.swift
//  Pods
//
//  Created by Japhet Ndhlovu on 12/5/24.
//
open class BaseSubmissionViewModel<ResultType: CaptureResult>: ObservableObject {
    // MARK: - Internal Properties

    var result: SmileIDResult<ResultType>?

    // MARK: - Methods to Override

    /// Creates the submission object for the job
    /// - Returns: A BaseJobSubmission instance
    open func createSubmission() throws -> BaseJobSubmission<ResultType> {
        fatalError("Must be implemented by subclass")
    }

    /// Called when job is in processing state
    open func triggerProcessingState() {
        fatalError("Must be implemented by subclass")
    }

    /// Handles successful job submission
    /// - Parameter data: The result data
    open func handleSuccess(data _: ResultType) {
        fatalError("Must be implemented by subclass")
    }

    /// Handles job submission error
    /// - Parameter error: The error that occurred
    open func handleError(error _: Error) {
        fatalError("Must be implemented by subclass")
    }

    /// Handles submission files for the given job ID
    /// - Parameter jobId: The job ID
    open func handleSubmissionFiles(jobId _: String) throws {
        fatalError("Must be implemented by subclass")
    }

    /// Handles offline success scenario
    open func handleOfflineSuccess() {
        fatalError("Must be implemented by subclass")
    }

    // MARK: - Internal Methods

    /// Handles proxy error scenarios
    /// - Parameters:
    ///   - jobId: The job ID
    ///   - error: The error that occurred
    func proxyErrorHandler(jobId: String, error: Error) {
        // First handle SmileIDError specific cases
        if let smileError = error as? SmileIDError {
            do {
                let didMoveToSubmitted = try LocalStorage.handleOfflineJobFailure(jobId: jobId, error: smileError)

                if didMoveToSubmitted {
                    try handleSubmissionFiles(jobId: jobId)
                }

                // Check if we should handle this as an offline success case
                if SmileID.allowOfflineMode && SmileIDError.isNetworkFailure(error: smileError) {
                    handleOfflineSuccess()
                    return
                }

                // If not a network failure or offline mode isn't allowed, handle as regular error
                handleError(error: smileError)
            } catch {
                // If handling offline failure throws, pass through the original error
                handleError(error: smileError)
            }
            return
        }

        // Handle non-SmileIDError cases
        handleError(error: error)
    }

    /// Submit job with given parameters
    /// - Parameters:
    ///   - jobId: The job ID
    ///   - skipApiSubmission: If true, skips API submission
    ///   - offlineMode: If true, runs in offline mode
    func submitJob(
        jobId: String,
        skipApiSubmission: Bool = false,
        offlineMode: Bool = SmileID.allowOfflineMode
    ) {
        triggerProcessingState()

        Task {
            do {
                let submission = try createSubmission()
                let submissionResult = try await submission.executeSubmission(
                    skipApiSubmission: skipApiSubmission,
                    offlineMode: offlineMode
                )

                await MainActor.run {
                    self.result = submissionResult

                    switch submissionResult {
                    case let .success(success):
                        handleSuccess(data: success.result)
                    case let .error(error):
                        proxyErrorHandler(jobId: jobId, error: error)
                    }
                }
            } catch {
                await MainActor.run {
                    proxyErrorHandler(jobId: jobId, error: error)
                }
            }
        }
    }
}
