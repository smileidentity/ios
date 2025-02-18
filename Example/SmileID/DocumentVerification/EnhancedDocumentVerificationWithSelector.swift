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
           let captureBothSides
        {
            SmileID.enhancedDocumentVerificationScreen(
                config: DocumentVerificationConfig(
                    userId: userId,
                    jobId: jobId,
                    // we need to fetch consent from the services endpoint
                    consentInformation: ConsentInformation(
                        consentGrantedDate: Date().toISO8601WithMilliseconds(),
                        personalDetailsConsentGranted: true,
                        contactInformationConsentGranted: true,
                        documentInformationConsentGranted: true
                    ),
                    countryCode: countryCode,
                    documentType: documentType,
                    captureBothSides: captureBothSides,
                    allowGalleryUpload: true
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
