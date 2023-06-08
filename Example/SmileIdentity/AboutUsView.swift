import SwiftUI
import SmileID

struct AboutUsView: View {

    init() {
        UITableView.appearance().backgroundColor = offWhiteUIColor
        UITableViewCell.appearance().backgroundColor = offWhiteUIColor
    }
    var body: some View {
        NavigationView {
            VStack(spacing: 15) {
                AboutUsCell(imageName: "info.circle.fill", title: "About Us") {}
                AboutUsCell(imageName: "star.fill", title: "Visit our website") {openUrl("https://smileidentity.com")}
                AboutUsCell(imageName: "envelope.fill", title: "Contact support") {openUrl("https://smileidentity.com/contact-us")}
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

struct AboutUsView_Previews: PreviewProvider {
    static var previews: some View {
        AboutUsView()
    }
}
