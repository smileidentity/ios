import SwiftUI

struct DocumentConfirmationView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 49) {
            VStack(spacing: 16) {
                Text("Hello, World!")
                    .multilineTextAlignment(.center)
                    .font(SmileID.theme.header1)
                    .foregroundColor(SmileID.theme.accent)
                    .lineSpacing(0.98)
                Text("callout")
                    .multilineTextAlignment(.center)
                    .font(SmileID.theme.header5)
                    .foregroundColor(SmileID.theme.tertiary)
                    .lineSpacing(1.3)
            }

            Image("")

            VStack(spacing: 16) {
                SmileButton(style: .secondary,
                            title: "button1",
                            clicked: {})
                SmileButton(style: .secondary,
                            title: "button1",
                            clicked: {})
            }
        }
    }
}

struct DocumentConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentConfirmationView()
    }
}
