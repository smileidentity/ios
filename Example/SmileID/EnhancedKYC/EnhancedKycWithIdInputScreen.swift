import Foundation
import SmileID
import SwiftUI
struct EnhancedKycWithIdInputScreen: View {
    let delegate: EnhancedKycResultDelegate

    @State private var selectedCountry: CountryInfo?
    @ObservedObject var viewModel: EnhancedKycWithIdInputScreenViewModel

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
            VStack {
                SearchableDropdownSelector(
                    items: countryList,
                    selectedItem: selectedCountry,
                    itemDisplayName: { $0.name },
                    onItemSelected: { selectedCountry = $0 }
                )
                if let selectedCountry = selectedCountry {
                    RadioGroupSelector(
                        title: "Select ID Type",
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
            }
        case .consent(let country, let idType, let requiredFields):
            SmileID.consentScreen(
                partnerIcon: UIImage(named: "SmileLogo")!,
                partnerName: "Smile ID",
                productName: "ID",
                partnerPrivacyPolicy: URL(string: "https://usesmileid.com")!,
                showAttribution: true,
                onConsentGranted: {
                    viewModel.onConsentGranted(
                        country: country,
                        idType: idType,
                        requiredFields: requiredFields)
                },
                onConsentDenied: { delegate.didError(error: SmileIDError.consentDenied) }
            )
        case .idInput(let country, let idType, let requiredFields):
            IdInfoInputScreen(
                selectedCountry: country,
                selectedIdType: idType,
                header: "Enter ID Information",
                requiredFields: requiredFields,
                onResult: viewModel.onIdFieldsEntered
            ).frame(maxWidth: .infinity)
        case .processing(let state):
            ProcessingScreen(
                processingState: state,
                inProgressTitle: "Processing Enhanced KYC…",
                inProgressSubtitle: "Just a few more seconds",
                inProgressIcon: SmileIDResourcesHelper.DocumentProcessing,
                successTitle: "Enhanced KYC Complete",
                successSubtitle: "You can now proceed",
                successIcon: SmileIDResourcesHelper.CheckBold,
                errorTitle: "Enhanced KYC Failed",
                errorSubtitle: "This could be because of internet connectivity",
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
    }}
