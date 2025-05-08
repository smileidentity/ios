import Foundation
import XCTest
@testable import SmileID

class ConsentInformationTests: XCTestCase {
    
    func testConsentInformationEncoding() throws {
        // given
        let consentInformation = ConsentInformation(
            consentGrantedDate: "2025-04-01T15:16:03.246Z",
            personalDetails: true,
            contactInformation: true,
            documentInformation: true
        )
        
        // when
        let encoder = JSONEncoder()
        let data = try encoder.encode(consentInformation)
        let jsonString = String(data: data, encoding: .utf8)!
        
        // then
        XCTAssertTrue(jsonString.contains("\"consented\""))
        XCTAssertTrue(jsonString.contains("\"consent_granted_date\""))
        XCTAssertTrue(jsonString.contains("\"personal_details\""))
        XCTAssertTrue(jsonString.contains("\"contact_information\""))
        XCTAssertTrue(jsonString.contains("\"document_information\""))
        
        // Verify the exact structure
        let expectedJsonPattern = """
        {"consented":{"consent_granted_date":"2025-04-01T15:16:03.246Z","personal_details":true,"contact_information":true,"document_information":true}}
        """
        
        // Remove whitespace for comparison
        let normalizedJsonString = jsonString.replacingOccurrences(of: " ", with: "")
                                             .replacingOccurrences(of: "\n", with: "")
        let normalizedExpectedJson = expectedJsonPattern.replacingOccurrences(of: " ", with: "")
                                                       .replacingOccurrences(of: "\n", with: "")
        
        XCTAssertEqual(normalizedJsonString, normalizedExpectedJson)
    }
    
    func testConsentInformationDecoding() throws {
        // given
        let jsonString = """
        {
            "consented": {
                "consent_granted_date": "2025-04-01T15:16:03.246Z", 
                "personal_details": true,
                "contact_information": false,
                "document_information": true
            }
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // when
        let decoder = JSONDecoder()
        let consentInformation = try decoder.decode(ConsentInformation.self, from: jsonData)
        
        // then
        XCTAssertEqual(consentInformation.consented.consentGrantedDate, "2025-04-01T15:16:03.246Z")
        XCTAssertEqual(consentInformation.consented.personalDetails, true)
        XCTAssertEqual(consentInformation.consented.contactInformation, false)
        XCTAssertEqual(consentInformation.consented.documentInformation, true)
    }
}