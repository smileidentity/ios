import SmileID
import SwiftUI

struct EnhancedDocumentVerificationWithSelector: View {
    @State private var countryCode: String?
    @State private var documentType: String?
    @State private var captureBothSides: Bool?

    let userId: String
    let jobId: String
    let delegate: EnhancedDocumentVerificationResultDelegate

    var body: some View {
        if let countryCode,
           let documentType,
           let captureBothSides {
            SmileID.enhancedDocumentVerificationScreen(
                userId: userId,
                jobId: jobId,
                countryCode: countryCode,
                documentType: documentType,
                captureBothSides: captureBothSides,
                allowGalleryUpload: true,
                // we need to fetch consent from the services endpoint
                consentInformation: ConsentInformation(
                    consentGrantedDate: Date().toISO8601WithMilliseconds(),
                    personalDetails: true,
                    contactInformation: true,
                    documentInformation: true
                ),
                delegate: delegate
            )
        } else {
            DocumentVerificationIdTypeSelector(
                jobType: .enhancedDocumentVerification
            ) { countryCode, documentType, captureBothSides in
                self.countryCode = countryCode
                self.documentType = documentType
                self.captureBothSides = captureBothSides
            }
        }
    }
}
