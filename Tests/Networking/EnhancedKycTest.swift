import Foundation
@testable import SmileID
import XCTest

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

  func testEnhancedKycRequestWithLegacyConsent() throws {
    // given - using the legacy consent API for backward compatibility
    let legacyConsent = ConsentInformation(
      consentGrantedDate: Date().toISO8601WithMilliseconds(),
      personalDetailsConsentGranted: true,
      contactInfoConsentGranted: true,
      documentInfoConsentGranted: true)

    let request = EnhancedKycRequest(
      country: "country",
      idType: "idType",
      idNumber: "idNumber",
      consentInformation: legacyConsent,
      callbackUrl: "callbackUrl",
      partnerParams: PartnerParams(
        jobId: "", userId: "", jobType: .enhancedKyc, extras: ["key1": "value1"]),
      sourceSdk: "ios",
      sourceSdkVersion: "10.0.0-test",
      timestamp: "timestamp",
      signature: "signature")

    // when
    let encoder = JSONEncoder()
    let data = try encoder.encode(request)
    let jsonString = String(data: data, encoding: .utf8)!

    // then
    // Verify the consent information is properly encoded
    assert(jsonString.contains("\"consent_information\""))
    assert(jsonString.contains("\"consented\""))
    assert(jsonString.contains("\"personal_details\""))
    assert(jsonString.contains("\"contact_information\""))
    assert(jsonString.contains("\"document_information\""))
  }

  func testEnhancedKycRequestWithFactoryConsent() throws {
    // given - using the factory method for creating consent
    let factoryConsent = ConsentInformation.createLegacy(
      consentGrantedDate: Date().toISO8601WithMilliseconds(),
      personalDetailsConsentGranted: true,
      contactInfoConsentGranted: false,
      documentInfoConsentGranted: true)

    let request = EnhancedKycRequest(
      country: "country",
      idType: "idType",
      idNumber: "idNumber",
      consentInformation: factoryConsent,
      callbackUrl: "callbackUrl",
      partnerParams: PartnerParams(
        jobId: "", userId: "", jobType: .enhancedKyc, extras: ["key1": "value1"]),
      sourceSdk: "ios",
      sourceSdkVersion: "10.0.0-test",
      timestamp: "timestamp",
      signature: "signature")

    // when
    let encoder = JSONEncoder()
    let data = try encoder.encode(request)
    let jsonString = String(data: data, encoding: .utf8)!

    // then
    // Verify the consent information is properly encoded
    assert(jsonString.contains("\"consent_information\""))
    assert(jsonString.contains("\"consented\""))
    assert(jsonString.contains("\"personal_details\":true"))
    assert(jsonString.contains("\"contact_information\":false"))
    assert(jsonString.contains("\"document_information\":true"))
  }

  func testShouldIncludeCallbackUrlForEnhancedKycAsync() throws {
    // given
    let request = EnhancedKycRequest(
      country: "country",
      idType: "idType",
      idNumber: "idNumber",
      consentInformation: ConsentInformation(
        consented: ConsentedInformation(
          consentGrantedDate: Date().toISO8601WithMilliseconds(),
          personalDetails: true,
          contactInformation: true,
          documentInformation: true)
      ),
      callbackUrl: "callbackUrl",
      partnerParams: PartnerParams(
        jobId: "", userId: "", jobType: .enhancedKyc, extras: ["key1": "value1"]),
      sourceSdk: "ios",
      sourceSdkVersion: "10.0.0-beta05",
      timestamp: "timestamp",
      signature: "signature")

    // when
    let json = try String(decoding: JSONEncoder().encode(request), as: UTF8.self)

    // then
    assert(json.contains("callback_url"))
  }
}
