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

private struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
