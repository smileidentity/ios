import SwiftUI
import SmileID

struct AboutUsView: View {

    init() {
        UITableView.appearance().backgroundColor = offWhiteUIColor
        UITableViewCell.appearance().backgroundColor = offWhiteUIColor
    }
    var body: some View {
        NavigationView {
            List {
                HStack(spacing: 10) {
                    Image(systemName: "info.circle.fill")
                    Text("Who we are")
                }
                    Button(action: {
                        if let url = URL(string: "https://www.mylink.com") {
                            UIApplication.shared.open(url)
                        }
                    }, label: {
                        HStack(spacing: 10) {
                            Image(systemName: "star.fill")
                            Text("Visit our website")
                        }
                    })

                Button(action: {
                    if let url = URL(string: "https://www.mylink.com") {
                        UIApplication.shared.open(url)
                    }
                }, label: {
                    HStack(spacing: 10) {
                        Image(systemName: "envelope.fill")
                        Text("Contact support")
                    }
                })

            }.font(SmileID.theme.body)
                .background(offWhite)
                .navigationBarTitle("Smile ID", displayMode: .inline)
                .navigationBarColor(sand)
        }
    }
}

struct AboutUsView_Previews: PreviewProvider {
    static var previews: some View {
        AboutUsView()
    }
}
