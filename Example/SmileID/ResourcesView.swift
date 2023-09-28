import SwiftUI

struct ResourcesView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                ResourceCell(
                    title: "Explore Documentation",
                    caption: "Read everything relating to our stack"
                ) {
                    openUrl("https://docs.smileidentity.com/")
                }

                ResourceCell(
                    title: "Privacy Policy",
                    caption: "Learn more about how we handle data"
                ) {
                    openUrl("https://smileidentity.com/privacy-policy")
                }

                ResourceCell(title: "View FAQs", caption: "Explore frequently asked questions") {
                    openUrl("https://docs.smileidentity.com/further-reading/faqs")
                }

                ResourceCell(
                    title: "Supported ID Types and Documents",
                    caption: "See our coverage range across the continent"
                ) {
                    openUrl("https://docs.smileidentity.com/supported-id-types/for-individuals-kyc")
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

                AboutUsCell(imageName: "envelope.fill", title: "Testing") {
                    openUrl("blah")
                }

                Spacer()
            }
                .padding()
                .background(offWhite.edgesIgnoringSafeArea(.all))
                .navigationBarTitle("Smile ID", displayMode: .inline)
        }
    }
}

struct ResourcesView_Previews: PreviewProvider {
    static var previews: some View {
        ResourcesView()
    }
}
