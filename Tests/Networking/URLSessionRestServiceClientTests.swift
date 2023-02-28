import Foundation
import XCTest
import Combine
@testable import SmileIdentity

class URLSessionRestServiceClientTests: BaseTestCase {
    var mockURL: URL!
    var mockServiceHeaderProvider: MockServiceHeaderProvider!
    var mockSessionPublisher: MockURLSessionPublisher!
    var serviceUnderTest: URLSessionRestServiceClient!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockServiceHeaderProvider = MockServiceHeaderProvider()
        mockSessionPublisher = MockURLSessionPublisher()
        mockDependencyContainer.register(ServiceHeaderProvider.self) { self.mockServiceHeaderProvider }

        serviceUnderTest = URLSessionRestServiceClient(session: mockSessionPublisher)
    }

    func testSendReturnsPublisherWithSuccessResponse() throws {
        let expectedURL = URL(string: "https://example.com")!
        let expectedData = try JSONEncoder().encode(TestResponse(status: true, message: "Success"))
        let expectedResponse: URLResponse = HTTPURLResponse(url: expectedURL,
                                                            statusCode: 200,
                                                            httpVersion: nil,
                                                            headerFields: nil)!
        mockSessionPublisher.expectedResponse = expectedResponse
        mockSessionPublisher.expectedData = expectedData
        let request = RestRequest(url: expectedURL, method: .get)
        let result: AnyPublisher<TestResponse, Error> = serviceUnderTest.send(request: request)
        let response = try `await`(result)
        XCTAssert(response.status)
    }

    func testSendReturnsPublisherWithSuccessResponseAnd201ResponseCode() throws {
        let expectedURL = URL(string: "https://example.com")!
        let expectedData = try JSONEncoder().encode(TestResponse(status: true, message: "Success"))
        let expectedResponse: URLResponse = HTTPURLResponse(url: expectedURL,
                                                            statusCode: 201,
                                                            httpVersion: nil,
                                                            headerFields: nil)!

        mockSessionPublisher.expectedResponse = expectedResponse
        mockSessionPublisher.expectedData = expectedData
        let request = RestRequest(url: expectedURL, method: .get)
        let result: AnyPublisher<TestResponse, Error> = serviceUnderTest.send(request: request)
        let response = try `await`(result)
        XCTAssert(response.status)
    }

    func testGetURLRequestSetsCorrectHeaders() throws {
        let expectedURL = URL(string: "https://example.com")!
        let expectedHeaders: [HTTPHeader] = [HTTPHeader(name: "Header", value: "Value")]
        let request = RestRequest(url: expectedURL, method: .get, headers: expectedHeaders)
        mockServiceHeaderProvider.expectedHeaders = expectedHeaders
        let urlRequest = try request.getURLRequest()
        XCTAssertEqual(urlRequest.allHTTPHeaderFields!, expectedHeaders.toDictionary())

    }

    func testGetURLRequestSetsCorrectQueryParameters() throws {
        let expectedURL = URL(string: "https://example.com?expand[]=plan&expand[]=number")!
        let expectedHeaders: [HTTPHeader] = [HTTPHeader(name: "Header", value: "Value")]
        let expectedData = try JSONEncoder().encode(TestResponse(status: true, message: "Success"))
        let expectedResponse: URLResponse = HTTPURLResponse(url: expectedURL,
                                                            statusCode: 200,
                                                            httpVersion: nil,
                                                            headerFields: nil)!
        let expectedPublisher = Just((data: expectedData, response: expectedResponse))
            .setFailureType(to: URLError.self)
            .eraseToAnyPublisher()

        let queryParameters = [HTTPQueryParameters(key: "expand[]", values: ["plan", "number"])]
        let request = RestRequest(url: expectedURL, method: .get, queryParameters: queryParameters)
        mockServiceHeaderProvider.expectedHeaders = expectedHeaders
        let urlRequest = try request.getURLRequest()
        XCTAssertEqual(urlRequest.url!, expectedURL)

    }

    func testSendReturnsPublisherWithFailureResponseWhenHttpResponseIsNotSuccessful() throws {
        let expectedURL = URL(string: "https://example.com")!
        let expectedData = try JSONEncoder().encode(TestResponse(status: true, message: "Success"))
        let expectedResponse: URLResponse = HTTPURLResponse(url: expectedURL,
                                                            statusCode: 500,
                                                            httpVersion: nil,
                                                            headerFields: nil)!
        mockSessionPublisher.expectedResponse = expectedResponse
        mockSessionPublisher.expectedData = expectedData
        let request = RestRequest(url: expectedURL, method: .get)

        let result: AnyPublisher<TestResponse, Error> = serviceUnderTest.send(request: request)
        do {
            _ = try `await`(result)
            XCTFail("Send should have not succeeded")
        } catch {
            XCTAssert(error is APIError)
        }
    }

}

struct TestResponse: Codable {
    var status: Bool
    var message: String
}
