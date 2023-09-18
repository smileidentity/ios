import SwiftUI
import SmileID

struct CountryRow: View {
    @State var country: String
    var body: some View {
        Text(country)
            .multilineTextAlignment(.leading)
            .foregroundColor(SmileID.theme.accent)

    }
}

struct CountryRow_Previews: PreviewProvider {
    static var previews: some View {
        CountryRow(country: "Nigeria")
    }
}
