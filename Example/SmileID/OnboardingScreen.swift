import SmileID
import SwiftUI

@available(iOS 14.0, *)
struct OnboardingScreen: View {
    @State private var showManualEntrySheet = false
    @State private var errorMessage: String?

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
                .font(SmileID.theme.header4)
                .padding(.vertical)

            // Create a clickable link that points to https://portal.usesmileid.com/sdk
            Link(
                "https://portal.usesmileid.com/sdk",
                destination: URL(string: "https://portal.usesmileid.com/sdk")!
            )
                .font(SmileID.theme.body)
                .foregroundColor(SmileID.theme.accent)
                .padding(.vertical)

            Spacer()

            Button(
                action: { print("TODO") },
                label: {
                    Spacer()
                    HStack {
                        Image(systemName: "qrcode")
                            .foregroundColor(SmileID.theme.onDark)
                        Text("Scan Configuration QR Code")
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
                    Text("Enter Configuration Manually")
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
                    if updateSmileConfig(smileConfig) {
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
    }
}

private func updateSmileConfig(_ configJson: String) -> Bool {
    do {
        let _ = try JSONDecoder().decode(Config.self, from: configJson.data(using: .utf8)!)
        UserDefaults.standard.set(configJson, forKey: "smileConfig")
        return true
    } catch {
        print("Error decoding new config: \(error)")
        return false
    }
}
