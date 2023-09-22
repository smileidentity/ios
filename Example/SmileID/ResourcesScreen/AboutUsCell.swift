import SwiftUI
import SmileID

struct AboutUsCell: View {
    let imageName: String
    let title: String
    let action: () -> Void
    
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

struct AboutUsCell_Previews: PreviewProvider {
    static var previews: some View {
        AboutUsCell(imageName: "info.circle.fill", title: "About Us") {}
    }
}
