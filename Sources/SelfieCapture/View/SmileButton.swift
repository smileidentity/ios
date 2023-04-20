import SwiftUI

struct SmileButton: View {
    var title: LocalizedStringKey
    var titleColor = SmileIdentity.theme.onDark
    var backgroundColor: Color = SmileIdentity.theme.accent
    var inactiveColour: Color?
    var clicked: (() -> Void)
    var body: some View {
        Button(action: clicked) {
            Text(title, bundle: .module)
                .padding(14)
                .font(SmileIdentity.theme.button)
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
