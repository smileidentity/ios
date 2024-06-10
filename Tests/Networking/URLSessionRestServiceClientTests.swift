import Foundation
import XCTest
import Combine
@testable import SmileID

class URLSessionRestServiceClientTests: BaseTestCase {
    var mockURL: URL!
    var mockServiceHeaderProvider: MockServiceHeaderProvider!
    var mockSession: MockURLSession!
    var serviceUnderTest: URLSessionRestServiceClient!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockServiceHeaderProvider = MockServiceHeaderProvider()
        mockSession = MockURLSession()
        mockDependencyContainer.register(ServiceHeaderProvider.self) {
            self.mockServiceHeaderProvider
        }

        serviceUnderTest = URLSessionRestServiceClient()
    }

    func testSendReturnsPublisherWithSuccessResponse() async throws {
        let expectedURL = URL(string: "https://example.com")!
        let expectedData = try JSONEncoder().encode(TestResponse(status: true, message: "Success"))
        let expectedResponse: URLResponse = HTTPURLResponse(
            url: expectedURL,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        mockSession.expectedResponse = expectedResponse
        mockSession.expectedData = expectedData
        let request = RestRequest(url: expectedURL, method: .get)
        let response: TestResponse = try await serviceUnderTest.send(request: request)
        XCTAssert(response.status)
    }

    func testSendReturnsPublisherWithSuccessResponseAnd201ResponseCode() async throws {
        let expectedURL = URL(string: "https://example.com")!
        let expectedData = try JSONEncoder().encode(TestResponse(status: true, message: "Success"))
        let expectedResponse: URLResponse = HTTPURLResponse(
            url: expectedURL,
            statusCode: 201,
            httpVersion: nil,
            headerFields: nil
        )!

        mockSession.expectedResponse = expectedResponse
        mockSession.expectedData = expectedData
        let request = RestRequest(url: expectedURL, method: .get)
        let response: TestResponse = try await serviceUnderTest.send(request: request)
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
        let queryParameters = [HTTPQueryParameters(key: "expand[]", values: ["plan", "number"])]
        let request = RestRequest(url: expectedURL, method: .get, queryParameters: queryParameters)
        mockServiceHeaderProvider.expectedHeaders = expectedHeaders
        let urlRequest = try request.getURLRequest()
        XCTAssertEqual(urlRequest.url!, expectedURL)
    }

    func testSendReturnsPublisherWithFailureResponseWhenHttpResponseIsNotSuccessful() async throws {
        let expectedURL = URL(string: "https://example.com")!
        let expectedData = try JSONEncoder().encode(TestResponse(status: true, message: "Success"))
        let expectedResponse: URLResponse = HTTPURLResponse(
            url: expectedURL,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )!
        mockSession.expectedResponse = expectedResponse
        mockSession.expectedData = expectedData
        let request = RestRequest(url: expectedURL, method: .get)

        do {
            let response: TestResponse = try await serviceUnderTest.send(request: request)
            XCTFail("Send should have not succeeded")
        } catch {
            XCTAssert(error is SmileIDError)
        }
    }
}

struct TestResponse: Codable {
    var status: Bool
    var message: String
}
