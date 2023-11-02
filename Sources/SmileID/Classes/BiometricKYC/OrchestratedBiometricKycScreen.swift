import Combine
import SwiftUI

struct OrchestratedBiometricKycScreen: View {
    let userId: String
    let jobId: String
    let partnerIcon: UIImage
    let partnerName: String
    let productName: String
    let partnerPrivacyPolicy: URL
    let showInstructions: Bool
    let showAttribution: Bool
    let allowAgentMode: Bool
    let delegate: BiometricKycResultDelegate
    @ObservedObject private var viewModel: OrchestratedBiometricKycViewModel

    @State private var selectedCountry: CountryInfo?

    init(
        idInfo: IdInfo?,
        userId: String,
        jobId: String,
        partnerIcon: UIImage,
        partnerName: String,
        productName: String,
        partnerPrivacyPolicy: URL,
        showInstructions: Bool,
        showAttribution: Bool,
        allowAgentMode: Bool,
        delegate: BiometricKycResultDelegate
    ) {
        self.userId = userId
        self.jobId = jobId
        self.partnerIcon = partnerIcon
        self.partnerName = partnerName
        self.productName = productName
        self.partnerPrivacyPolicy = partnerPrivacyPolicy
        self.showInstructions = showInstructions
        self.showAttribution = showAttribution
        self.allowAgentMode = allowAgentMode
        self.delegate = delegate
        viewModel = OrchestratedBiometricKycViewModel(userId: userId, jobId: jobId, idInfo: idInfo)
    }

    var body: some View {
        switch viewModel.step {
        case .loading(let messageKey):
            VStack {
                ActivityIndicator(isAnimating: true).padding()
                Text(SmileIDResourcesHelper.localizedString(for: messageKey))
                    .font(SmileID.theme.body)
                    .foregroundColor(SmileID.theme.onLight)
            }
                .frame(maxWidth: .infinity)
        case .idTypeSelection(let countryList):
            SearchableDropdownSelector(
                items: countryList,
                selectedItem: selectedCountry,
                itemDisplayName: { $0.name },
                onItemSelected: { selectedCountry = $0 }
            )
            if let selectedCountry = selectedCountry {
                RadioGroupSelector(
                    title: SmileIDResourcesHelper.localizedString(for: "BiometricKYC.SelectIdType"),
                    items: selectedCountry.availableIdTypes,
                    itemDisplayName: { $0.label },
                    onItemSelected: { idType in
                        viewModel.onIdTypeSelected(
                            country: selectedCountry.countryCode,
                            idType: idType.idTypeKey,
                            requiredFields: idType.requiredFields ?? []
                        )
                    }
                )
            }
        case .consent(let country, let idType, let requiredFields):
            OrchestratedConsentScreen(
                partnerIcon: partnerIcon,
                partnerName: partnerName,
                productName: productName,
                partnerPrivacyPolicy: partnerPrivacyPolicy,
                showAttribution: showAttribution,
                onConsentGranted: {
                    viewModel.onConsentGranted(
                        country: country,
                        idType: idType,
                        requiredFields: requiredFields)
                },
                onConsentDenied: { delegate.didError(error: SmileIDError.consentDenied) }
            )
        case .idInput(let country, let idType, let requiredFields, let showReEntryBlurb):
            IdInfoInputScreen(
                selectedCountry: country,
                selectedIdType: idType,
                title: SmileIDResourcesHelper.localizedString(
                    for: "BiometricKYC.EnterIdInfoTitle"
                ),
                subtitle: showReEntryBlurb ? SmileIDResourcesHelper.localizedString(
                    for: "BiometricKYC.EnterIdInfo.ReEntrySubtitle"
                ) : nil,
                requiredFields: requiredFields,
                onResult: viewModel.onIdFieldsEntered
            ).frame(maxWidth: .infinity)
        case .selfie:
            SelfieCaptureView(
                viewModel: SelfieCaptureViewModel(
                    userId: userId,
                    jobId: jobId,
                    isEnroll: false,
                    shouldSubmitJob: false,
                    // imageCaptureDelegate is just for image capture, not job result
                    imageCaptureDelegate: viewModel
                ),
                delegate: nil
            )
        case .processing(let state):
            ProcessingScreen(
                processingState: state,
                inProgressTitle: SmileIDResourcesHelper.localizedString(
                    for: "BiometricKYC.Processing.Title"
                ),
                inProgressSubtitle: SmileIDResourcesHelper.localizedString(
                    for: "BiometricKYC.Processing.Subtitle"
                ),
                inProgressIcon: SmileIDResourcesHelper.DocumentProcessing,
                successTitle: SmileIDResourcesHelper.localizedString(
                    for: "BiometricKYC.Success.Title"
                ),
                successSubtitle: SmileIDResourcesHelper.localizedString(
                    for: "BiometricKYC.Success.Subtitle"
                ),
                successIcon: SmileIDResourcesHelper.CheckBold,
                errorTitle: SmileIDResourcesHelper.localizedString(for: "BiometricKYC.Error.Title"),
                errorSubtitle: SmileIDResourcesHelper.localizedString(
                    for: "BiometricKYC.Error.Subtitle"
                ),
                errorIcon: SmileIDResourcesHelper.Scan,
                continueButtonText: SmileIDResourcesHelper.localizedString(
                    for: "Confirmation.Continue"
                ),
                onContinue: { viewModel.onFinished(delegate: delegate) },
                retryButtonText: SmileIDResourcesHelper.localizedString(for: "Confirmation.Retry"),
                onRetry: viewModel.onRetry,
                closeButtonText: SmileIDResourcesHelper.localizedString(for: "Confirmation.Close"),
                onClose: { viewModel.onFinished(delegate: delegate) }
            )
        }
    }
}
