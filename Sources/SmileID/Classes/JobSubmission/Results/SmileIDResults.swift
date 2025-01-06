//
//  SmileIDResults.swift
//  Pods
//
//  Created by Japhet Ndhlovu on 12/5/24.
//

// Specific result types conforming to CaptureResult
public protocol CaptureResult {
    var didSubmitJob: Bool { get }
}

public struct SmartSelfieResult: CaptureResult {
    public let captureData: SelfieCaptureResult
    public let didSubmitJob: Bool
    public let apiResponse: SmartSelfieResponse?

    public init(
        captureData: SelfieCaptureResult,
        didSubmitJob: Bool,
        apiResponse: SmartSelfieResponse?
    ) {
        self.captureData = captureData
        self.didSubmitJob = didSubmitJob
        self.apiResponse = apiResponse
    }
}

public struct DocumentVerificationResult: CaptureResult {
    public let captureData: DocumentCaptureResult
    public let didSubmitJob: Bool

    public init(
        captureData: DocumentCaptureResult,
        didSubmitJob: Bool
    ) {
        self.captureData = captureData
        self.didSubmitJob = didSubmitJob
    }
}

public struct EnhancedDocumentVerificationResult: CaptureResult {
    public let captureData: DocumentCaptureResult
    public let didSubmitJob: Bool

    public init(
        captureData: DocumentCaptureResult,
        didSubmitJob: Bool
    ) {
        self.captureData = captureData
        self.didSubmitJob = didSubmitJob
    }
}

public struct BiometricKycResult: CaptureResult {
    public let captureData: SelfieCaptureResult
    public let didSubmitJob: Bool

    public init(
        captureData: SelfieCaptureResult,
        didSubmitJob: Bool
    ) {
        self.captureData = captureData
        self.didSubmitJob = didSubmitJob
    }
}

// MARK: - Generic Result Type

public enum SmileIDResult<T: CaptureResult> {
    case success(Success<T>)
    case error(Error)

    public struct Success<ResultType: CaptureResult> {
        public let result: ResultType

        public init(result: ResultType) {
            self.result = result
        }
    }
}
