import SmileID
import SwiftUI

struct SettingsView: View {
    @State private var showSheet = false

    var body: some View {
        NavigationView {
            let scrollView = ScrollView {
                VStack(spacing: 16) {
                    SettingsCell(
                        imageName: "doc.badge.gearshape",
                        title: "Update Smile Config"
                    ) {
                        print("Update Smile Config")
                        showSheet.toggle()
                    }
                    Spacer()
                }
                    .sheet(isPresented: $showSheet) {
                        // Use a ZStack here so that the backgroundColor fills up the entire modal,
                        // otherwise some jarring white sections get left at the top and bottom
                        // https://stackoverflow.com/a/73561306
                        ZStack {
                            SmileID.theme.backgroundLightest.edgesIgnoringSafeArea(.all)
                            let content = SmileConfigEntryView { newConfig in
                                print("New Smile Config: \(newConfig)")
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
                    .padding()
                    .navigationBarTitle("Settings", displayMode: .large)
                    .background(SmileID.theme.backgroundLight.edgesIgnoringSafeArea(.all))
            }
                .background(SmileID.theme.backgroundLight.edgesIgnoringSafeArea(.all))

            if #available(iOS 16.0, *) {
                scrollView.toolbarBackground(SmileID.theme.backgroundLight, for: .navigationBar)
            }
            scrollView
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
    let onNewSmileConfig: (_ newConfig: String) -> Void

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
            textField
                .autocorrectionDisabled(true)
                .foregroundColor(SmileID.theme.onLight)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 10).stroke(SmileID.theme.accent, lineWidth: 2)
                )
                .padding()

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
