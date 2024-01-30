import SmileID
import SwiftUI

struct WelcomeScreen: View {
    @State private var showManualEntrySheet = false
    @State private var showQrCodeScanner = false
    @State private var errorMessage: String?
    @Binding var showSuccess: Bool
    @State private var partnerId: String?

    var body: some View {
        VStack(alignment: .leading) {
            Image("SmileLogo")
                .resizable()
                .scaledToFit()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: 64)
                .padding(.vertical, 100)
            
            Text("Welcome to our sample App!")
                .font(SmileID.theme.header1)
                .foregroundColor(SmileID.theme.accent)
                .padding(.vertical)
            
            Text("To begin testing, you need to add a configuration from the Smile Portal")
                .font(EpilogueFont.regular(with: 16))
                .foregroundColor(SmileID.theme.onLight)
                .padding(.vertical)
            
            Link(
                "https://portal.usesmileid.com/sdk",
                destination: URL(string: "https://portal.usesmileid.com/sdk")!
            )
            .font(SmileID.theme.body)
            .foregroundColor(SmileID.theme.accent)
            .padding(.vertical)

            Spacer()

            Button(
                action: { showQrCodeScanner = true },
                label: {
                    Spacer()
                    HStack {
                        Image(systemName: "qrcode")
                            .foregroundColor(SmileID.theme.onDark)
                        Text("Scan Configuration QR")
                            .font(SmileID.theme.button)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }
            )
            .foregroundColor(SmileID.theme.onDark)
            .background(SmileID.theme.accent)
            .cornerRadius(60)
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            .padding(.vertical, 4)

            Button(
                action: { showManualEntrySheet = true },
                label: {
                    Text("Add Config Manually")
                        .padding()
                        .font(SmileID.theme.button)
                        .frame(maxWidth: .infinity)
                }
            )
            .foregroundColor(SmileID.theme.accent)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 60)
                    .stroke(SmileID.theme.accent, lineWidth: 4)
            )
            .cornerRadius(60)
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
        }
        .padding()
        .background(SmileID.theme.backgroundLightest.ignoresSafeArea())
        .sheet(isPresented: $showManualEntrySheet) {
            let content = SmileConfigEntryView(errorMessage: errorMessage) { smileConfig in
                let response = updateSmileConfig(smileConfig)
                if let smilePartnerId = response {
                    partnerId = smilePartnerId
                    showSuccess = true
                    showManualEntrySheet = false
                } else {
                    errorMessage = "Invalid Smile Config"
                }
            }
            if #available(iOS 16.0, *) {
                content
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            } else {
                content
            }
        }
        .sheet(isPresented: $showQrCodeScanner) {
            CodeScannerView(
                codeTypes: [.qr],
                scanInterval: 1,
                showViewfinder: true
            ) { response in
                if case let .success(result) = response {
                    let configJson = result.string
                    let response = updateSmileConfig(configJson)
                    if let smilePartnerId = response {
                        partnerId = smilePartnerId
                        showSuccess = true
                        showQrCodeScanner = false
                    }
                }
            }
        }
        .overlay(
            Group {
                if showSuccess {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                        .overlay(
                            AlertView(
                                icon: Image(systemName: "checkmark.circle.fill"),
                                title: "Configuration Added",
                                description: "Welcome Partner \(String(describing: partnerId)), you can "
                                + "now proceed to the home screen of the Sample App",
                                buttonTitle: "Continue",
                                onClick: {
                                    showSuccess = false
                                }
                            )
                            .padding([.leading, .trailing], 20)
                        )
                }
            }
        )
    }
}

private func updateSmileConfig(_ configJson: String) -> String? {
    do {
        let config = try JSONDecoder().decode(Config.self, from: configJson.data(using: .utf8)!)
        UserDefaults.standard.set(configJson, forKey: "smileConfig")
        return config.partnerId
    } catch {
        print("Error decoding new config: \(error)")
        return nil
    }
}
