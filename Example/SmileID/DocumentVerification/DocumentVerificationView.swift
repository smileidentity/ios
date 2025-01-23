import SmileID
import SwiftUI

struct DocumentVerificationView: View {
    let userId: String
    let jobId: String
    let verificationDetails: DocumentVerificationDetails
    let delegate: DocumentVerificationResultDelegate

    var body: some View {
        SmileID.documentVerificationScreen(
            userId: userId,
            jobId: jobId,
            countryCode: verificationDetails.countryCode,
            documentType: verificationDetails.documentType,
            captureBothSides: verificationDetails.captureBothSides,
            allowGalleryUpload: true,
            delegate: delegate
        )
    }
}
