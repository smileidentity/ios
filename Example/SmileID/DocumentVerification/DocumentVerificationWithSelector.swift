import SmileID
import SwiftUI

struct DocumentVerificationWithSelector: View {
    private var verificationDetails: DocumentVerificationDetails?

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
        if #available(iOS 17.1, *) {
            Self._printChanges()
        } else {
            // Fallback on earlier versions
        }
        return VStack {
            if let verificationDetails {
                DocumentVerificationView(
                    userId: userId,
                    jobId: jobId,
                    verificationDetails: verificationDetails,
                    delegate: delegate
                )
            } else {
                DocumentVerificationIdTypeSelector(
                    jobType: .documentVerification
                ) { countryCode, documentType, captureBothSides in
                    print("change was supposed to occur")
//                    self.verificationDetails = DocumentVerificationDetails(
//                        countryCode: countryCode,
//                        documentType: documentType,
//                        captureBothSides: captureBothSides
//                    )
                }
            }
        }
//        .onChange(of: verificationDetails) { oldValue, newValue in
//            print("who is changing you 2")
//        }
    }
}
