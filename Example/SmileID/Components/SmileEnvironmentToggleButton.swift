import SwiftUI
import SmileID

struct SmileEnvironmentToggleButton: View {
    @State private var isProduction: Bool = !SmileID.useSandbox

    var body: some View {
        Button(
            action: {},
            label: {
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
        )
    }
}

extension Color {
    static let amberColor = Color(red: 45 / 255, green: 43 / 255, blue: 42 / 255)
}

private struct SmileEnvironmentToggleButton_Previews: PreviewProvider {
    static var previews: some View {
        SmileEnvironmentToggleButton()
    }
}
