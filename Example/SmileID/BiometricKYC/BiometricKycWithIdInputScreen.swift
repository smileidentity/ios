import Foundation
import SmileID
import SwiftUI

struct BiometricKycWithIdInputScreen: View {
  let delegate: BiometricKycResultDelegate

  @State private var selectedCountry: CountryInfo?
  @StateObject var viewModel: BiometricKycWithIdInputScreenViewModel

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
          onItemSelected: { selectedCountry = $0 })
        if let selectedCountry {
          RadioGroupSelector(
            title: "Select ID Type",
            items: selectedCountry.availableIdTypes,
            itemDisplayName: { $0.label },
            onItemSelected: { idType in
              viewModel.onIdTypeSelected(
                country: selectedCountry.countryCode,
                idType: idType.idTypeKey,
                requiredFields: idType.requiredFields ?? [])
            })
        }
      }
    case .consent(let country, let idType, let requiredFields):
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
            requiredFields: requiredFields)
        },
        onConsentDenied: { delegate.didError(error: SmileIDError.consentDenied) })
    case .idInput(let country, let idType, let consentInformation, let requiredFields):
      IdInfoInputScreen(
        selectedCountry: country,
        selectedIdType: idType,
        consentInformation: consentInformation,
        header: "Enter ID Information",
        requiredFields: requiredFields,
        onResult: viewModel.onIdFieldsEntered).frame(maxWidth: .infinity)
    case .sdk(let idInfo, let consentInformation):
      SmileID.biometricKycScreen(
        idInfo: idInfo,
        userId: viewModel.userId,
        jobId: viewModel.jobId,
        allowAgentMode: true,
        useStrictMode: false,
        consentInformation: consentInformation,
        delegate: delegate)
    }
  }
}
