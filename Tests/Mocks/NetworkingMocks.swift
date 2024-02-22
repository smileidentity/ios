// swiftlint:disable force_cast
import Combine
import Foundation
@testable import SmileID
import XCTest

class MockServiceHeaderProvider: ServiceHeaderProvider {
    var expectedHeaders = [HTTPHeader(name: "", value: "")]

    func provide(request _: RestRequest) -> [HTTPHeader]? {
        expectedHeaders
    }
}

class MockURLSessionPublisher: URLSessionPublisher {
    var expectedData = Data()
    var expectedResponse = URLResponse()

    func send(
        request _: URLRequest
    ) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
        Result.Publisher((expectedData, expectedResponse))
            .eraseToAnyPublisher()
    }
}

class NewMockSmileIDServiceable: Mock<SmileIDServiceable>, SmileIDServiceable {
    func authenticate(
        request: AuthenticationRequest
    ) -> AnyPublisher<AuthenticationResponse, Error> {
        return accept(args: [request]) as! AnyPublisher<AuthenticationResponse, Error>
    }

    func prepUpload(request: PrepUploadRequest) -> AnyPublisher<PrepUploadResponse, Error> {
        return accept(args: [request]) as! AnyPublisher<PrepUploadResponse, Error>
    }

    func upload(zip: Data, to url: String) -> AnyPublisher<UploadResponse, Error> {
        return accept(checkArgs: [url], actionArgs: [zip]) as! AnyPublisher<UploadResponse, Error>
    }

    func doEnhancedKycAsync(
        request: EnhancedKycRequest
    ) -> AnyPublisher<EnhancedKycAsyncResponse, Error> {
        return accept(args: [request]) as! AnyPublisher<EnhancedKycAsyncResponse, Error>
    }

    func doEnhancedKyc(request: EnhancedKycRequest) -> AnyPublisher<EnhancedKycResponse, Error> {
        return accept(args: [request]) as! AnyPublisher<EnhancedKycResponse, Error>
    }

    func getJobStatus<T>(
        request: JobStatusRequest
    ) -> AnyPublisher<JobStatusResponse<T>, Error> where T: JobResult {
        return accept(args: [request]) as! AnyPublisher<JobStatusResponse<T>, Error>
    }

    func getServices() -> AnyPublisher<ServicesResponse, Error> {
        return accept(args: []) as! AnyPublisher<ServicesResponse, Error>
    }

    func getProductsConfig(
        request: ProductsConfigRequest
    ) -> AnyPublisher<ProductsConfigResponse, Error> {
        return accept(args: [request]) as! AnyPublisher<ProductsConfigResponse, Error>
    }

    func getValidDocuments(
        request: ProductsConfigRequest
    ) -> AnyPublisher<ValidDocumentsResponse, Error> {
        return accept(args: [request]) as! AnyPublisher<ValidDocumentsResponse, Error>
    }

    func requestBvnTotpMode(request: BvnTotpRequest) -> AnyPublisher<BvnTotpResponse, Error> {
        return accept(args: [request]) as! AnyPublisher<BvnTotpResponse, Error>
    }

    func requestBvnOtp(request: BvnTotpModeRequest) -> AnyPublisher<BvnTotpModeResponse, Error> {
        return accept(args: [request]) as! AnyPublisher<BvnTotpModeResponse, Error>
    }

    func submitBvnOtp(request: SubmitBvnTotpRequest) -> AnyPublisher<SubmitBvnTotpResponse, Error> {
        return accept(args: [request]) as! AnyPublisher<SubmitBvnTotpResponse, Error>
    }
}
