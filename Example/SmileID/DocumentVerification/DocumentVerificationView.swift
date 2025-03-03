import SmileID
import SwiftUI

struct DocumentVerificationView: View {
    let userId: String
    let jobId: String
    let verificationDetails: DocumentVerificationDetails
    let delegate: DocumentVerificationResultDelegate

    var body: some View {
        SmileID.documentVerificationScreen(
            config: DocumentVerificationConfig(
                userId: userId,
                jobId: jobId,
                documentType: verificationDetails.documentType,
                captureBothSides: verificationDetails.captureBothSides,
                allowGalleryUpload: true,
                countryCode: verificationDetails.countryCode
            ),
            delegate: delegate
        )
    }
}
