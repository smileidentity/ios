@testable import SmileID
import XCTest

class PartnerParamsTests: XCTestCase {
  func testEncoding() throws {
    // Define an instance of PartnerParams
    let jobType: JobType = .smartSelfieEnrollment
    let params = PartnerParams(
      jobId: "123",
      userId: "456",
      jobType: jobType,
      extras: ["extraKey1": "extraValue1", "extraKey2": "extraValue2"])

    // Encode the params instance
    let encoder = JSONEncoder()
    let data = try encoder.encode(params)
    let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]

    // Verify the encoded data
    XCTAssertEqual(dictionary?["job_id"] as? String, "123")
    XCTAssertEqual(dictionary?["user_id"] as? String, "456")
    XCTAssertEqual(dictionary?["extraKey1"] as? String, "extraValue1")
    XCTAssertEqual(dictionary?["extraKey2"] as? String, "extraValue2")
    XCTAssertNil(dictionary?["extras"])
  }
}
