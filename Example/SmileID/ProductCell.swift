import SwiftUI
import SmileID

struct ProductCell: View {
    var productImage: String
    var productName: String

    var body: some View {
        VStack(spacing: 25) {
            Image(productImage)
                .resizable()
                .frame(width: 50, height: 50)
            Text(productName)
                .multilineTextAlignment(.center)
                .font(SmileID.theme.header4)
                .foregroundColor(offWhite)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: 150)
        .background(SmileID.theme.accent)
        .cornerRadius(6)
    }
}

struct ProductCell_Previews: PreviewProvider {
    static var previews: some View {
        ProductCell(productImage: "userauth",
                    productName: "SmartSelfie™ \nAuthentication")
    }
}

let offWhite = Color(hex: "#F9F0E7")
let sand = Color(hex: "#DBDBC4")
let offWhiteUIColor = UIColor(red: 0.976, green: 0.941, blue: 0.906, alpha: 1)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let alpha, red, green, blue: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (alpha, red, green, blue) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (alpha, red, green, blue) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (alpha, red, green, blue) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (alpha, red, green, blue) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: Double(alpha) / 255
        )
    }
}
