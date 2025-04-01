// swiftlint:disable force_cast
import Foundation
@testable import SmileID
import XCTest

class MockServiceHeaderProvider: ServiceHeaderProvider {
    var expectedHeaders = [HTTPHeader(name: "", value: "")]

    func provide(request _: RestRequest) -> [HTTPHeader]? {
        expectedHeaders
    }
}

class MockURLSession: URLSessionPublisher {

    var expectedData = Data()
    var expectedResponse = URLResponse()

    func send(
        request _: URLRequest
    ) async throws -> (data: Data, response: URLResponse) {
        return (expectedData, expectedResponse)
    }
}

class MockSmileIdentityService: SmileIDServiceable {
    func authenticate(request _: AuthenticationRequest) async throws -> AuthenticationResponse {
        let params = PartnerParams(
            jobId: "jobid",
            userId: "userid",
            jobType: .enhancedKyc,
            extras: ["key1": "value1"]
        )
        let response = AuthenticationResponse(
            success: true,
            signature: "sig",
            timestamp: "time",
            partnerParams: params
        )
        if MockHelper.shouldFail {
            throw SmileIDError.request(URLError(.resourceUnavailable))
        } else {
            return response
        }
    }

    func prepUpload(request _: PrepUploadRequest) async throws -> PrepUploadResponse {
        let response = PrepUploadResponse(
            code: "code",
            refId: "refid",
            uploadUrl: "",
            smileJobId: "8950"
        )
        if MockHelper.shouldFail {
            throw SmileIDError.request(URLError(.resourceUnavailable))
        } else {
            return response
        }
    }

    func upload(zip _: Data = Data(), to _: String = "") async throws -> Data {
        if MockHelper.shouldFail {
            throw SmileIDError.request(URLError(.resourceUnavailable))
        } else {
            return Data()
        }
    }

    func doEnhancedKycAsync(
        request _: EnhancedKycRequest
    ) async throws -> EnhancedKycAsyncResponse {
        if MockHelper.shouldFail {
            let error = SmileIDError.request(URLError(.resourceUnavailable))
            throw error
        } else {
            let response = EnhancedKycAsyncResponse(success: true)
            return response
        }
    }

    func doEnhancedKyc(
        request _: EnhancedKycRequest
    ) async throws -> EnhancedKycResponse {
        if MockHelper.shouldFail {
            let error = SmileIDError.request(URLError(.resourceUnavailable))
            throw error
        } else {
            let response = EnhancedKycResponse(
                smileJobId: "",
                partnerParams: PartnerParams(jobId: "", userId: "", jobType: .enhancedKyc, extras: [:]),
                resultText: "",
                resultCode: "",
                country: "",
                actions: Actions(
                    humanReviewCompare: .approved,
                    humanReviewLivenessCheck: .approved,
                    humanReviewSelfieCheck: .approved,
                    humanReviewUpdateSelfie: .approved,
                    livenessCheck: .approved,
                    selfieCheck: .approved,
                    registerSelfie: .approved,
                    returnPersonalInfo: .approved,
                    selfieProvided: .approved,
                    selfieToIdAuthorityCompare: .approved,
                    selfieToIdCardCompare: .approved,
                    selfieToRegisteredSelfieCompare: .approved,
                    updateRegisteredSelfieOnFile: .approved,
                    verifyIdNumber: .approved
                ),
                idType: "",
                idNumber: ""
            )
            return response
        }
    }

    func doSmartSelfieEnrollment(
        signature _: String,
        timestamp _: String,
        selfieImage _: MultipartBody,
        livenessImages _: [MultipartBody],
        userId _: String?,
        partnerParams _: [String: String]?,
        callbackUrl _: String?,
        sandboxResult _: Int?,
        allowNewEnroll _: Bool?,
        failureReason: FailureReason?,
        metadata _: Metadata
    ) async throws -> SmartSelfieResponse {
        if MockHelper.shouldFail {
            let error = SmileIDError.request(URLError(.resourceUnavailable))
            throw error
        } else {
            let response = SmartSelfieResponse(
                code: "",
                createdAt: "",
                jobId: "",
                jobType: JobTypeV2.smartSelfieEnrollment,
                message: "", partnerId: "",
                partnerParams: [:],
                status: SmartSelfieStatus.approved,
                updatedAt: "",
                userId: ""
            )
            return response
        }
    }

    func doSmartSelfieAuthentication(
        signature _: String,
        timestamp _: String,
        userId _: String,
        selfieImage _: MultipartBody,
        livenessImages _: [MultipartBody],
        partnerParams _: [String: String]?,
        callbackUrl _: String?,
        sandboxResult _: Int?,
        failureReason: FailureReason?,
        metadata _: Metadata
    ) async throws -> SmartSelfieResponse {
        if MockHelper.shouldFail {
            let error = SmileIDError.request(URLError(.resourceUnavailable))
            throw error
        } else {
            let response = SmartSelfieResponse(
                code: "",
                createdAt: "",
                jobId: "",
                jobType: JobTypeV2.smartSelfieAuthentication,
                message: "", partnerId: "",
                partnerParams: [:],
                status: SmartSelfieStatus.approved,
                updatedAt: "",
                userId: ""
            )
            return response
        }
    }

    func getJobStatus<T: JobResult>(
        request _: JobStatusRequest
    ) async throws -> JobStatusResponse<T> {
        let response = JobStatusResponse<T>(jobComplete: MockHelper.jobComplete)
        if MockHelper.shouldFail {
            throw SmileIDError.request(URLError(.resourceUnavailable))
        } else {
            return response
        }
    }

    func getServices() async throws -> ServicesResponse {
        var response: ServicesResponse
        do {
            response = try ServicesResponse(
                bankCodes: [],
                hostedWeb: HostedWeb(from: JSONDecoder() as! Decoder)
            )
        } catch {
            throw SmileIDError.request(URLError(.resourceUnavailable))
        }

        if MockHelper.shouldFail {
            throw SmileIDError.request(URLError(.resourceUnavailable))
        } else {
            return response
        }
    }

    func getProductsConfig(
        request _: ProductsConfigRequest
    ) async throws -> ProductsConfigResponse {
        var response: ProductsConfigResponse
        response = ProductsConfigResponse(
            consentRequired: [:],
            idSelection: IdSelection(
                basicKyc: [:],
                biometricKyc: [:],
                enhancedKyc: [:],
                documentVerification: [:]
            )
        )

        if MockHelper.shouldFail {
            throw SmileIDError.request(URLError(.resourceUnavailable))
        } else {
            return response
        }
    }

    func getValidDocuments(
        request _: ProductsConfigRequest
    ) async throws -> ValidDocumentsResponse {
        let response = ValidDocumentsResponse(validDocuments: [ValidDocument]())
        if MockHelper.shouldFail {
            throw SmileIDError.request(URLError(.resourceUnavailable))
        } else {
            return response
        }
    }

    public func requestBvnTotpMode(
        request _: BvnTotpRequest
    ) async throws -> BvnTotpResponse {
        let response = BvnTotpResponse(
            success: true,
            message: "success",
            modes: [],
            sessionId: "sessionId",
            timestamp: "timestamp",
            signature: "signature"
        )
        if MockHelper.shouldFail {
            throw SmileIDError.request(URLError(.resourceUnavailable))
        } else {
            return response
        }
    }

    public func requestBvnOtp(
        request _: BvnTotpModeRequest
    ) async throws -> BvnTotpModeResponse {
        let response = BvnTotpModeResponse(
            success: true,
            message: "success",
            timestamp: "timestamp",
            signature: "signature"
        )
        if MockHelper.shouldFail {
            throw SmileIDError.request(URLError(.resourceUnavailable))
        } else {
            return response
        }
    }

    public func submitBvnOtp(
        request _: SubmitBvnTotpRequest
    ) async throws -> SubmitBvnTotpResponse {
        let response = SubmitBvnTotpResponse(
            success: true,
            message: "success",
            timestamp: "timestamp",
            signature: "signature"
        )
        if MockHelper.shouldFail {
            throw SmileIDError.request(URLError(.resourceUnavailable))
        } else {
            return response
        }
    }
}

class MockResultDelegate: SmartSelfieResultDelegate {
    var successExpectation: XCTestExpectation?
    var failureExpectation: XCTestExpectation?

    func didSucceed(
        selfieImage _: URL,
        livenessImages _: [URL],
        apiResponse _: SmartSelfieResponse?
    ) {
        successExpectation?.fulfill()
    }

    func didError(error _: Error) {
        failureExpectation?.fulfill()
    }
    
    func didCancel() {}
}

enum MockHelper {
    static var shouldFail = false
    static var jobComplete = true
}
