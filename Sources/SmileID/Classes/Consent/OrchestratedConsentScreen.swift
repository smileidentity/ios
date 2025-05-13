import SwiftUI

/// Responsible for showing the consent screen and the consent denied (try again) screens.
public struct OrchestratedConsentScreen: View {
    let partnerIcon: UIImage
    let partnerName: String
    let productName: String
    let partnerPrivacyPolicy: URL
    let showAttribution: Bool
    let onConsentGranted: (ConsentInformation) -> Void
    let onConsentDenied: () -> Void
    @State private var showTryAgain = false

    public var body: some View {
        if showTryAgain {
            ConsentDeniedScreen(
                showAttribution: showAttribution,
                onGoBack: { showTryAgain = false },
                onCancel: onConsentDenied
            )
        } else {
            ConsentScreen(
                partnerIcon: partnerIcon,
                partnerName: partnerName,
                productName: productName,
                partnerPrivacyPolicy: partnerPrivacyPolicy,
                showAttribution: showAttribution,
                onConsentGranted: onConsentGranted,
                onCancel: { showTryAgain = true }
            )
        }
    }
}

private let consentInfos = [(
    SmileIDResourcesHelper.ConsentPersonalInfo,
    "Consent.PersonalDetailsTitle",
    "Consent.PersonalDetailsSubtitle"
), (
    SmileIDResourcesHelper.ConsentContactDetails,
    "Consent.ContactInfoTitle",
    "Consent.ContactInfoSubtitle"
), (
    SmileIDResourcesHelper.ConsentDocumentInfo,
    "Consent.DocumentInfoTitle",
    "Consent.DocumentInfoSubtitle"
)]

/// Consent screen for SmileID
public struct ConsentScreen: View {
    let partnerIcon: UIImage
    let partnerName: String
    let productName: String
    let partnerPrivacyPolicy: URL
    let showAttribution: Bool
    let onConsentGranted: (ConsentInformation) -> Void
    let onCancel: () -> Void

    public var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 16) {
                    Image(uiImage: partnerIcon)
                        .resizable()
                        .scaledToFit()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 64)
                        .padding()
                    Text("\(partnerName) wants to access your \(productName) information")
                        .font(SmileID.theme.header2)
                        .foregroundColor(SmileID.theme.accent)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                    Text("This will allow \(partnerName) to:")
                        .font(SmileID.theme.body)
                        .foregroundColor(SmileID.theme.onLight)
                        .padding(16)

                    VStack(spacing: 16) {
                        ForEach(0 ..< consentInfos.count, id: \.self) { index in
                            let consentInfo = consentInfos[index]
                            HStack(alignment: .top, spacing: 16) {
                                Image(uiImage: consentInfo.0)
                                    .resizable()
                                    .scaledToFit()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 36, height: 36)
                                    .padding(.horizontal, 12)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(SmileIDResourcesHelper.localizedString(for: consentInfo.1))
                                        .font(SmileID.theme.body)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .foregroundColor(SmileID.theme.accent)
                                    Text(SmileIDResourcesHelper.localizedString(for: consentInfo.2))
                                        .font(SmileID.theme.header5)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .foregroundColor(SmileID.theme.onLight)
                                }
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(4)

                    Spacer()
                }
            }
            VStack {
                Divider()
                Text(
                    SmileIDResourcesHelper.localizedString(
                        for: "Consent.ViewPrivacyPolicy",
                        partnerName
                    )
                )
                .foregroundColor(SmileID.theme.accent)
                .font(SmileID.theme.body)
                .onTapGesture { UIApplication.shared.open(partnerPrivacyPolicy) }
                Text(SmileIDResourcesHelper.localizedString(for: "Consent.Disclaimer", partnerName))
                    .foregroundColor(SmileID.theme.onLight)
                    .font(SmileID.theme.body)
                    .multilineTextAlignment(.center)
                VStack(spacing: 8) {
                    Button {
                        let consentInfo = ConsentInformation(
                            consented: ConsentedInformation(
                                consentGrantedDate: Date().toISO8601WithMilliseconds(),
                                personalDetails: true,
                                contactInformation: true,
                                documentInformation: true
                            )
                        )
                        onConsentGranted(consentInfo)
                    } label: {
                        Text(SmileIDResourcesHelper.localizedString(for: "Consent.Allow"))
                            .padding(14)
                            .font(SmileID.theme.button)
                            .frame(maxWidth: .infinity)
                    }
                    .background(SmileID.theme.accent)
                    .foregroundColor(SmileID.theme.onDark)
                    .cornerRadius(60)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)

                    Button(action: onCancel) {
                        Text(SmileIDResourcesHelper.localizedString(for: "Consent.Cancel"))
                            .padding(14)
                            .font(SmileID.theme.button)
                            .frame(maxWidth: .infinity)
                    }
                    .background(Color.clear)
                    .foregroundColor(SmileID.theme.accent)
                    .overlay(
                        RoundedRectangle(cornerRadius: 60)
                            .stroke(SmileID.theme.accent, lineWidth: 4)
                    )
                    .cornerRadius(60)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    if showAttribution {
                        Image(uiImage: SmileIDResourcesHelper.SmileEmblem)
                    }
                }
                .padding(5)
            }
        }.preferredColorScheme(.light)
    }
}

/// Asks user to confirm that they do actually want to deny consent
public struct ConsentDeniedScreen: View {
    let showAttribution: Bool
    let onGoBack: () -> Void
    let onCancel: () -> Void

    public var body: some View {
        VStack(spacing: 8) {
            Image(uiImage: SmileIDResourcesHelper.ConsentDenied)
                .font(.system(size: 100))
                .padding()
                .padding(.bottom, 32)
            Text(SmileIDResourcesHelper.localizedString(for: "Consent.Denied"))
                .font(SmileID.theme.header1)
                .foregroundColor(SmileID.theme.error)
                .padding()
            Text(SmileIDResourcesHelper.localizedString(for: "Consent.DeniedTitle"))
                .font(SmileID.theme.body)
                .foregroundColor(SmileID.theme.onLight)
                .padding()
            Text(SmileIDResourcesHelper.localizedString(for: "Consent.DeniedDescription"))
                .foregroundColor(SmileID.theme.accent)
                .font(SmileID.theme.header2)
                .padding()
            Spacer()
            Button(action: onGoBack) {
                Text(SmileIDResourcesHelper.localizedString(for: "Consent.GoBack"))
                    .padding(14)
                    .font(SmileID.theme.button)
                    .frame(maxWidth: .infinity)
            }
            .background(SmileID.theme.accent)
            .foregroundColor(SmileID.theme.onDark)
            .cornerRadius(60)
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            Button(action: onCancel) {
                Text(SmileIDResourcesHelper.localizedString(for: "Consent.CancelVerification"))
                    .padding(14)
                    .font(SmileID.theme.button)
                    .foregroundColor(SmileID.theme.error)
                    .frame(maxWidth: .infinity)
            }
            .background(Color.clear)
            .foregroundColor(SmileID.theme.accent)
            .overlay(
                RoundedRectangle(cornerRadius: 60)
                    .stroke(SmileID.theme.accent, lineWidth: 4)
            )
            .cornerRadius(60)
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            if showAttribution {
                Image(uiImage: SmileIDResourcesHelper.SmileEmblem)
            }
        }.preferredColorScheme(.light)
    }
}
