import SmileID
import SwiftUI

struct ResourcesView: View {
    var body: some View {
        NavigationView {
            let scrollView = ScrollView {
                VStack(spacing: 16) {
                    ResourceCell(
                        title: "Explore Documentation",
                        caption: "Read everything relating to our stack"
                    ) {
                        openUrl("https://docs.usesmileid.com/")
                    }

                    ResourceCell(
                        title: "Privacy Policy",
                        caption: "Learn more about how we handle data"
                    ) {
                        openUrl("https://usesmileid.com/privacy-policy")
                    }

                    ResourceCell(title: "View FAQs", caption: "Explore frequently asked questions") {
                        openUrl("https://docs.usesmileid.com/further-reading/faqs")
                    }

                    ResourceCell(
                        title: "Supported ID Types and Documents",
                        caption: "See our coverage range across the continent"
                    ) {
                        openUrl("https://docs.usesmileid.com/supported-id-types/for-individuals-kyc")
                    }

                    AboutUsCell(imageName: "info.circle.fill", title: "About Us") {
                        openUrl("https://usesmileid.com/about-us")
                    }

                    AboutUsCell(imageName: "star.fill", title: "Visit our website") {
                        openUrl("https://usesmileid.com")
                    }

                    AboutUsCell(imageName: "envelope.fill", title: "Contact support") {
                        openUrl("https://usesmileid.com/contact-us")
                    }
                    Spacer()
                }
                    .padding()
                    .navigationBarTitle("Resources", displayMode: .large)
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

struct ResourceCell: View {
    let title: String
    let caption: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(SmileID.theme.button)
                        .foregroundColor(SmileID.theme.onLight)
                        .multilineTextAlignment(.leading)
                    Text(caption)
                        .font(SmileID.theme.body)
                        .foregroundColor(SmileID.theme.onLight)
                        .multilineTextAlignment(.leading)
                    Divider()
                        .padding(.top, 15)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(SmileID.theme.onLight)
            }
        }
    }
}

struct AboutUsCell: View {
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

private struct ResourcesView_Previews: PreviewProvider {
    static var previews: some View {
        ResourcesView()
    }
}
