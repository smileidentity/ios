import SmileID
import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                SettingsCell(
                    imageName: "doc.badge.gearshape",
                    title: "Update Smile Config"
                ) {
                    print("Update Smile Config")
                }
                Spacer()
            }
                .padding()
                .background(SmileID.theme.backgroundLight.edgesIgnoringSafeArea(.all))
                .navigationBarTitle("Settings", displayMode: .large)
        }
    }
}

struct SettingsCell: View {
    var imageName: String
    var title: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top) {
                Image(systemName: imageName)
                    .foregroundColor(SmileID.theme.onLight)
                VStack(alignment: .leading, spacing: 15) {
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

private struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
