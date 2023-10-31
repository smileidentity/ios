import SmileID
import SwiftUI

struct SettingsView: View {
    @ObservedObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationView {
            let scrollView = ScrollView {
                VStack(spacing: 16) {
                    SettingsCell(
                        imageName: "doc.badge.gearshape",
                        title: "Update Smile Config",
                        action: viewModel.onUpdateSmileConfigSelected
                    )
                    Spacer()
                }
                    .sheet(isPresented: $viewModel.showSheet) {
                        // Use a ZStack here so that the backgroundColor fills up the entire modal,
                        // otherwise some jarring white sections get left at the top and bottom
                        // https://stackoverflow.com/a/73561306
                        ZStack {
                            SmileID.theme.backgroundLightest.edgesIgnoringSafeArea(.all)
                            let content = SmileConfigEntryView(
                                errorMessage: viewModel.errorMessage,
                                onNewSmileConfig: viewModel.updateSmileConfig
                            )
                            if #available(iOS 16.0, *) {
                                content
                                    .presentationDetents([.medium])
                                    .presentationDragIndicator(.visible)
                            } else {
                                content
                            }
                        }
                    }
                    .padding()
                    .navigationBarTitle("Settings", displayMode: .large)
                    .background(SmileID.theme.backgroundLight.edgesIgnoringSafeArea(.all))
            }
                .background(SmileID.theme.backgroundLight.edgesIgnoringSafeArea(.all))

            if #available(iOS 16.0, *) {
                scrollView.toolbarBackground(SmileID.theme.backgroundLight, for: .navigationBar)
            } else {
                scrollView
            }
        }
    }
}

private struct SettingsCell: View {
    var imageName: String
    var title: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top) {
                Image(systemName: imageName)
                    .foregroundColor(SmileID.theme.onLight)
                VStack(alignment: .leading, spacing: 16) {
                    Text(title)
                        .font(SmileID.theme.button)
                        .foregroundColor(SmileID.theme.onLight)
                        .multilineTextAlignment(.leading)
                    Divider()
                }
            }
        }
    }
}

private struct SmileConfigEntryView: View {
    private let errorMessage: String?
    private let onNewSmileConfig: (_ newConfig: String) -> Void

    init(
        errorMessage: String? = nil,
        onNewSmileConfig: @escaping (_ newConfig: String) -> Void
    ) {
        self.errorMessage = errorMessage
        self.onNewSmileConfig = onNewSmileConfig
    }

    @State private var smileConfigTextFieldValue = ""
    var body: some View {
        VStack {
            Spacer()
            let textField = if #available(iOS 16.0, *) {
                AnyView(
                    TextField(
                        "Paste your Smile Config from the Portal here",
                        // smileConfigTextFieldValue,
                        text: $smileConfigTextFieldValue,
                        axis: .vertical
                    )
                        .textInputAutocapitalization(.none)
                        .lineLimit(10, reservesSpace: true)
                )
            } else {
                AnyView(
                    TextField(
                        "Paste your Smile Config from the Portal here",
                        text: $smileConfigTextFieldValue
                    )
                        .lineLimit(10)
                )
            }
            let strokeColor = errorMessage == nil ? SmileID.theme.accent : SmileID.theme.error
            textField
                .autocorrectionDisabled(true)
                .foregroundColor(SmileID.theme.onLight)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 10).stroke(strokeColor, lineWidth: 2)
                )
                .padding()
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(SmileID.theme.error)
                    .padding()
            }

            Spacer()

            Button(action: { onNewSmileConfig(smileConfigTextFieldValue) }) {
                Text("Update Smile Config")
                    .padding()
                    .font(SmileID.theme.button)
                    .frame(maxWidth: .infinity)
            }
                .foregroundColor(SmileID.theme.onDark)
                .background(SmileID.theme.accent)
                .cornerRadius(60)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(.vertical, 2)

            Button(action: { print("Scan QR Code from Portal") }) {
                Text("Scan QR Code from Portal")
                    .padding()
                    .font(SmileID.theme.button)
                    .frame(maxWidth: .infinity)
            }
                .foregroundColor(SmileID.theme.accent)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 60)
                        .stroke(SmileID.theme.accent, lineWidth: 4)
                )
                .cornerRadius(60)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(.vertical, 2)
        }
    }
}

private struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

class SettingsViewModel: ObservableObject {
    @Published @MainActor var errorMessage: String?
    @Published @MainActor var showSheet = false

    private let jsonDecoder = JSONDecoder()

    func onUpdateSmileConfigSelected() {
        DispatchQueue.main.async { self.showSheet = true }
    }

    func updateSmileConfig(_ configJson: String) {
        do {
            let config = try jsonDecoder.decode(Config.self, from: configJson.data(using: .utf8)!)
            SmileID.initialize(config: config)
            UserDefaults.standard.set(configJson, forKey: "smileConfig")
            DispatchQueue.main.async {
                self.errorMessage = nil
                self.showSheet = false
            }
        } catch {
            print("Error decoding new config: \(error)")
            DispatchQueue.main.async { self.errorMessage = "Invalid Config" }
        }
    }
}
