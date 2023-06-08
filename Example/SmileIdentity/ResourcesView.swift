import SwiftUI

struct ResourcesView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 15) {
                ResourceCell(title: "Explore Documentation", caption: "Read everything relating to our stack") {
                    openUrl("https://docs.smileidentity.com/")
                }
                ResourceCell(title: "Privacy Policy", caption: "Learn more about how we handle data") {
                    openUrl("https://smileidentity.com/privacy-policy")
                }
                ResourceCell(title: "View FAQs", caption: "Explore frequently asked questions") {
                    openUrl("https://docs.smileidentity.com/further-reading/faqs")
                }
                ResourceCell(title: "Supported ID Types and Documents", caption: "See our coverage range across the continent") {
                    openUrl("https://docs.smileidentity.com/supported-id-types/for-individuals-kyc")
                }
                
                Spacer()
                
            }
            .padding()
            .background(offWhite.edgesIgnoringSafeArea(.all))
            .navigationBarTitle("Smile ID", displayMode: .inline)
        }
    }

    func openUrl(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

struct ResourcesView_Previews: PreviewProvider {
    static var previews: some View {
        ResourcesView()
    }
}
