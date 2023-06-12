import SwiftUI
import SmileID

struct ResourceCell: View {
    var title: String
    var caption: String
    var action: (() -> Void)

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

struct ResourceCell_Previews: PreviewProvider {
    static var previews: some View {
        ResourceCell(title: "Explore Documentation", caption: "Read everything relating to our stack") {}
    }
}
