@testable import SmileID
import XCTest

final class CalculateSignatureTests: XCTestCase {
  func testHMACCalculationWithKnownValues() {
    let message = "testMessage"
    let key = "testKey"

    // Precomputed HMAC SHA-256 hash of "testMessage" with key "testKey" (in base64 format)
    let expectedHMACBase64 = "8N7PlLvnGgnE2gFU7+AkSxmAc02cXFkOLlFD5gTuOjo="

    guard let hmacData = message.hmac(algorithm: .SHA256, key: key) else {
      XCTFail("HMAC calculation failed")
      return
    }
    let computedHMACBase64 = hmacData.base64EncodedString()
    XCTAssertEqual(
      computedHMACBase64,
      expectedHMACBase64,
      "Calculated HMAC does not match expected value")
  }
}
