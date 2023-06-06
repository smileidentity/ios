import SwiftUI
import SmileID

struct ToggleButton: View {
    @State private var isProduction: Bool = false

    var body: some View {
        Button(action: {
            isProduction.toggle()
            SmileID.setEnvironment(useSandbox: !isProduction)
        }) {
            Text(isProduction ? "Production" : "Sandbox")
                .font(SmileID.theme.button)
                .foregroundColor(isProduction ? .green : .amberColor)
                .padding(.all, 10)
                .background(Color.clear)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isProduction ? .green : .amberColor, lineWidth: 1)
                )
        }
    }
}

extension Color {
    static let amberColor = Color(red: 1.0, green: 0.75, blue: 0.0)
}


struct ToggleButton_Previews: PreviewProvider {
    static var previews: some View {
        ToggleButton()
    }
}
