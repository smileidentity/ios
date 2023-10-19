import SwiftUI

struct OrchestratedBvnConsentScreen: View {
    // MARK: - Input Properties
    let userId: String
    let partnerIcon: UIImage
    let partnerName: String
    let partnerPrivacyPolicy: URL
    let onConsentGranted: () -> Void
    let onConsentDenied: () -> Void
    let showAttribution: Bool

    @ObservedObject private var viewModel: OrchestratedBvnConsentViewModel

    init(
        userId: String,
        partnerIcon: UIImage,
        partnerName: String,
        partnerPrivacyPolicy: URL,
        onConsentGranted: @escaping () -> Void,
        onConsentDenied: @escaping () -> Void,
        showAttribution: Bool
    ) {
        self.userId = userId
        self.partnerIcon = partnerIcon
        self.partnerName = partnerName
        self.partnerPrivacyPolicy = partnerPrivacyPolicy
        self.onConsentGranted = onConsentGranted
        self.onConsentDenied = onConsentDenied
        self.showAttribution = showAttribution
        viewModel = OrchestratedBvnConsentViewModel(userId: userId)
    }

    var body: some View {
        switch viewModel.currentScreen {
        case .consentScreen:
            EmptyView()
        case .bvnInputScreen:
            BvnInputScreen(
                showLoading: viewModel.showLoading,
                showError: viewModel.showError,
                supportingText: "Your BVN should be 11 digits long",
                errorMessage: "You have entered an invalid BVN. Please try again",
                onContinue: viewModel.submitUserBvn
            )
        case .chooseOtpDeliveryScreen:
            EmptyView()
        case .verifyOtpScreen:
            EmptyView()
        }
    }
}
