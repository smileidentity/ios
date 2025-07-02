import SmileID
import SwiftUI

struct DocumentVerificationWithSelector: View {
  @State private var verificationDetails: DocumentVerificationDetails?

  let userId: String
  let jobId: String
  let delegate: DocumentVerificationResultDelegate

  init(
    userId: String,
    jobId: String,
    delegate: DocumentVerificationResultDelegate
  ) {
    self.userId = userId
    self.jobId = jobId
    self.delegate = delegate
  }

  var body: some View {
    VStack {
      if let verificationDetails {
        DocumentVerificationView(
          userId: userId,
          jobId: jobId,
          verificationDetails: verificationDetails,
          delegate: delegate)
      } else {
        DocumentVerificationIdTypeSelector(
          jobType: .documentVerification
        ) { countryCode, documentType, captureBothSides in
          verificationDetails = DocumentVerificationDetails(
            countryCode: countryCode,
            documentType: documentType,
            captureBothSides: captureBothSides)
        }
      }
    }
  }
}
