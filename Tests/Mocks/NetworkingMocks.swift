import Foundation
import Combine
import XCTest
@testable import SmileID

class MockServiceHeaderProvider: ServiceHeaderProvider {
    var expectedHeaders = [HTTPHeader(name: "", value: "")]
    func provide(request: RestRequest) -> [HTTPHeader]? {
        return expectedHeaders
    }
}

class MockURLSessionPublisher: URLSessionPublisher {

    var expectedData = Data()
    var expectedResponse = URLResponse()

    func send(request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
        return Result.Publisher((expectedData, expectedResponse))
            .eraseToAnyPublisher()
    }
}

class MockSmileIdentityService: SmileIDServiceable {
    func getJobStatus(request: JobStatusRequest) -> AnyPublisher<JobStatusResponse, Error> {
        let response = JobStatusResponse(timestamp: "timestamp",
                                         jobComplete: true,
                                         jobSuccess: true,
                                         code: "2322")
        if MockHelper.shouldFail {
            return Fail(error: APIError.request(URLError(.resourceUnavailable)))
                .eraseToAnyPublisher()
        } else {
            return Result.Publisher(response)
                .eraseToAnyPublisher()
        }
    }

    func authenticate(request: AuthenticationRequest) -> AnyPublisher<AuthenticationResponse, Error> {
        let params = PartnerParams(jobId: "jobid",
                                   userId: "userid",
                                   jobType: .enhancedKyc)
        let response = AuthenticationResponse(success: true,
                                              signature: "sig",
                                              timestamp: "time",
                                              partnerParams: params)
        if MockHelper.shouldFail {
            return Fail(error: APIError.request(URLError(.resourceUnavailable)))
                .eraseToAnyPublisher()
        } else {
            return Result.Publisher(response)
                .eraseToAnyPublisher()
        }
    }

    func prepUpload(request: PrepUploadRequest) -> AnyPublisher<PrepUploadResponse, Error> {
        let response = PrepUploadResponse(code: "code",
                                          refId: "refid",
                                          uploadUrl: "",
                                          smileJobId: "8950")
        if MockHelper.shouldFail {
            return Fail(error: APIError.request(URLError(.resourceUnavailable)))
                .eraseToAnyPublisher()
        } else {
            return Result.Publisher(response)
                .eraseToAnyPublisher()
        }
    }

    func upload(zip: Data = Data(), to url: String = "") -> AnyPublisher<UploadResponse, Error> {
        let response = UploadResponse.response(data: Data())
        if MockHelper.shouldFail {
            return Fail(error: APIError.request(URLError(.resourceUnavailable)))
                .eraseToAnyPublisher()
        } else {
            return Result.Publisher(response)
                .eraseToAnyPublisher()
        }
    }
}

class MockResultDelegate: SmartSelfieResultDelegate {
    var successExpectation: XCTestExpectation?
    var failureExpection: XCTestExpectation?

    func didSucceed(selfieImage: Data, livenessImages: [Data], jobStatusResponse: JobStatusResponse) {
        successExpectation?.fulfill()
    }

    func didError(error: Error) {
        failureExpection?.fulfill()
    }
}

class MockHelper {
    static var shouldFail = false
}
