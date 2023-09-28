import Foundation
import XCTest
import Combine
@testable import SmileID

class EnhancedKycTest: BaseTestCase {
    func testShouldDecodeEnhancedKycAsyncResponseJson() throws {
        // given
        let json = """
                   {"success": true}
                   """.data(using: .ascii)!

        // when
        let response = try JSONDecoder().decode(EnhancedKycAsyncResponse.self, from: json)

        // then
        assert(response.success)
    }

    func testShouldIncludeCallbackUrlForEnhancedKycAsync() throws {
        // given
        let request = EnhancedKycRequest(
            country: "country",
            idType: "idType",
            idNumber: "idNumber",
            callbackUrl: "callbackUrl",
            partnerParams: PartnerParams(jobId: "", userId: "", jobType: .enhancedKyc),
            sourceSdk: "ios",
            sourceSdkVersion: "10.0.0-beta05",
            timestamp: "timestamp",
            signature: "signature"
        )

        // when
        let json = String(decoding: try JSONEncoder().encode(request), as: UTF8.self)

        // then
        assert(json.contains("callback_url"))
    }
}
