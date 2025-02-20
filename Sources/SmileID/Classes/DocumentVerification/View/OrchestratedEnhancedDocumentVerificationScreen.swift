import SwiftUI

struct OrchestratedEnhancedDocumentVerificationScreen: View {
    @State private var localMetadata = LocalMetadata()
    let config: DocumentVerificationConfig
    let onResult: EnhancedDocumentVerificationResultDelegate

    var body: some View {
        IOrchestratedDocumentVerificationScreen(
            config: config,
            onResult: onResult,
            viewModel: OrchestratedEnhancedDocumentVerificationViewModel(
                config: config,
                jobType: .enhancedDocumentVerification,
                localMetadata: localMetadata
            )
        ).environmentObject(localMetadata)
    }
}
