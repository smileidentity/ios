import SwiftUI

struct SmileButton: View {

    enum Style {
        case primary
        case secondary
    }

    var title: LocalizedStringKey
    var titleColor = SmileIdentity.theme.onDark
    var backgroundColor: Color = SmileIdentity.theme.accent
    var cornerRadius: CGFloat = 15
    var borderColor = Color.clear
    var inactiveColor: Color?
    var clicked: (() -> Void)
    var style: Style

    init(style: Style = .primary, title: LocalizedStringKey,
         backgroundColor: Color = SmileIdentity.theme.accent,
         clicked: @escaping (() -> Void)) {
        self.style = style
        self.title = title
        self.backgroundColor = backgroundColor
        self.clicked = clicked
        setup()
    }

    mutating func setup() {
        switch style {
        case .primary:
            backgroundColor = SmileIdentity.theme.accent
            titleColor = SmileIdentity.theme.onDark
            borderColor = .clear
            cornerRadius = 60
        case .secondary:
            backgroundColor = .clear
            titleColor = SmileIdentity.theme.accent
            borderColor = SmileIdentity.theme.accent
            cornerRadius = 15
        }
    }

    var body: some View {
        if let titleKey = title.stringKey {
            Button(action: clicked) {
                Text(SmileIDResourcesHelper.localizedString(for: titleKey))
                    .padding(14)
                    .font(SmileIdentity.theme.button)
                    .frame(maxWidth: .infinity)
        }
        .foregroundColor(titleColor)
                .background(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(borderColor, lineWidth: 4)
                )
                .cornerRadius(cornerRadius)
                .frame(maxWidth: .infinity)
        }
    }
}

struct SmileButton_Previews: PreviewProvider {
    static var previews: some View {
        SmileButton(title: "Instructions.Action",
                    backgroundColor: .blue,
                    clicked: {})
            .environment(\.locale, Locale(identifier: "en"))
    }
}
