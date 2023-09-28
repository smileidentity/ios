import SwiftUI
import SmileID

struct SmileTextField: View {

    // Constants, so all "TextFields will be the same in the app"
    let fontsize: CGFloat = 14
    let backgroundColor = SmileID.theme.backgroundLight
    let textColor = SmileID.theme.onLight

    // The @State Object
    @Binding var field: String

    // A custom variable for a "TextField"
    @State var isHighlighted = false
    var placeholder = ""

    var body: some View {
        TextField(placeholder, text: $field)
            .font(SmileID.theme.button)
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).fill(backgroundColor))
            .foregroundColor(textColor)
            .padding()
    }
}

struct SmileTextField_Previews: PreviewProvider {
    static var previews: some View {
        SmileTextField(field: .constant("Some user"))
    }
}
