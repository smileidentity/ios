import Foundation
import XCTest
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
            consentInformation: ConsentInformation(
                consentGrantedDate: Date().toISO8601WithMilliseconds(),
                personalDetails: true,
                contactInformation: true,
                documentInformation: true
            ),
            callbackUrl: "callbackUrl",
            partnerParams: PartnerParams(
                jobId: "", userId: "", jobType: .enhancedKyc, extras: ["key1": "value1"]
            ),
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
