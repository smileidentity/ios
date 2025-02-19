import SwiftUI

struct OrchestratedDocumentVerificationScreen: View {
    @State private var localMetadata = LocalMetadata()
    let config: DocumentVerificationConfig
    let onResult: DocumentVerificationResultDelegate

    var body: some View {
        IOrchestratedDocumentVerificationScreen(
            config: config,
            onResult: onResult,
            viewModel: OrchestratedDocumentVerificationViewModel(
                config: config,
                jobType: .documentVerification,
                localMetadata: localMetadata
            )
        ).environmentObject(localMetadata)
    }
}
