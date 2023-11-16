import Foundation
import SmileID
import SwiftUI

struct BiometricKycWithIdInputScreen: View {
    let delegate: BiometricKycResultDelegate

    @State private var selectedCountry: CountryInfo?
    @ObservedObject private var viewModel = BiometricKycWithIdInputScreenViewModel()

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
                header: SmileIDResourcesHelper.localizedString(
                    for: "BiometricKYC.EnterIdInfoTitle"
                ),
                requiredFields: requiredFields,
                onResult: viewModel.onIdFieldsEntered
            ).frame(maxWidth: .infinity)
        case .sdk(let idInfo):
            SmileID.biometricKycScreen(
                idInfo: idInfo,
                allowAgentMode: true,
                delegate: delegate
            )
        }
    }
}
