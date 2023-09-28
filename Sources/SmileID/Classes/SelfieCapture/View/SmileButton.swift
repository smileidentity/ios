import SwiftUI

public struct SmileButton: View {

    public enum Style {
        case primary
        case secondary
        case alternate
        case destructive
    }

    let title: LocalizedStringKey
    var titleColor = SmileID.theme.onDark
    var backgroundColor: Color = SmileID.theme.accent
    var cornerRadius: CGFloat = 15
    var borderColor = Color.clear
    var inactiveColor: Color?
    let clicked: () -> Void
    let style: Style

    public init(
        style: Style = .primary,
        title: LocalizedStringKey,
        backgroundColor: Color = SmileID.theme.accent,
        clicked: @escaping () -> Void
    ) {
        self.style = style
        self.title = title
        self.backgroundColor = backgroundColor
        self.clicked = clicked
        setup()
    }

    mutating func setup() {
        switch style {
        case .primary:
            backgroundColor = SmileID.theme.accent
            titleColor = SmileID.theme.onDark
            borderColor = .clear
            cornerRadius = 60
        case .secondary:
            backgroundColor = .clear
            titleColor = SmileID.theme.accent
            borderColor = SmileID.theme.accent
            cornerRadius = 15
        case .destructive:
            titleColor = SmileID.theme.error.opacity(0.8)
            backgroundColor = .clear
            borderColor = .clear
        case .alternate:
            backgroundColor = .clear
            titleColor = SmileID.theme.accent
            borderColor = .clear
        }
    }

    public var body: some View {
        if let titleKey = title.stringKey {
            Button(action: clicked) {
                Text(SmileIDResourcesHelper.localizedString(for: titleKey))
                    .padding(14)
                    .font(SmileID.theme.button)
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
        SmileButton(
            title: "Instructions.Action",
            backgroundColor: .blue,
            clicked: {}
        )
            .environment(\.locale, Locale(identifier: "en"))
    }
}
