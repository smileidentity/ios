import SwiftUI

struct SmileButton: View {
    var title: LocalizedStringKey
    var titleColor = Color.white
    var backgroundColor: Color = .digitalBlue
    var inactiveColour: Color?
    var clicked: (() -> Void)
    var body: some View {
        Button(action: clicked) {
            Text(title, bundle: .module)
                .padding(14)
                .font(Font.button)
                .frame(maxWidth: .infinity)
        }
        .foregroundColor(titleColor)
        .background(backgroundColor)
        .cornerRadius(15)
        .frame(maxWidth: .infinity)
    }
}

struct SmileButton_Previews: PreviewProvider {
    static var previews: some View {
        SmileButton(title: "Instructions.Action",
                    backgroundColor: .blue,
                    clicked: {}).loadCustomFonts()
            .environment(\.locale, Locale(identifier: "en"))
    }
}
