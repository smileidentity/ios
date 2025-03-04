import Foundation
import SmileID
import SwiftUI

struct BiometricKycWithIdInputScreen: View {
    let delegate: BiometricKycResultDelegate

    @State private var selectedCountry: CountryInfo?
    @StateObject var viewModel: BiometricKycWithIdInputScreenViewModel

    var body: some View {
        switch viewModel.step {
        case let .loading(messageKey):
            VStack {
                ActivityIndicator(isAnimating: true).padding()
                Text(SmileIDResourcesHelper.localizedString(for: messageKey))
                    .font(SmileID.theme.body)
                    .foregroundColor(SmileID.theme.onLight)
            }
            .frame(maxWidth: .infinity)
        case let .idTypeSelection(countryList):
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
        case let .consent(country, idType, requiredFields):
            SmileID.consentScreen(
                partnerIcon: UIImage(named: "SmileLogo")!,
                partnerName: "Smile ID",
                productName: "ID",
                partnerPrivacyPolicy: URL(string: "https://usesmileid.com")!,
                showAttribution: true,
                onConsentGranted: { consentInformation in
                    viewModel.onConsentGranted(
                        country: country,
                        idType: idType,
                        consentInformation: consentInformation,
                        requiredFields: requiredFields
                    )
                },
                onConsentDenied: { delegate.didError(error: SmileIDError.consentDenied) }
            )
        case let .idInput(country, idType, consentInformation, requiredFields):
            IdInfoInputScreen(
                selectedCountry: country,
                selectedIdType: idType,
                consentInformation: consentInformation,
                header: "Enter ID Information",
                requiredFields: requiredFields,
                onResult: viewModel.onIdFieldsEntered
            ).frame(maxWidth: .infinity)
        case let .sdk(idInfo, consentInformation):
            SmileID.biometricKycScreen(
                config: BiometricVerificationConfig(
                    userId: viewModel.userId,
                    jobId: viewModel.jobId,
                    useStrictMode: false,
                    allowAgentMode: true,
                    idInfo: idInfo,
                    consentInformation: consentInformation
                ),
                delegate: delegate
            )
        }
    }
}
