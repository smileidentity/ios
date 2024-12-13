import SwiftUI

struct UserInstructionsView: View {
    var instruction: String
    var message: String?

    var body: some View {
        VStack {
            Spacer(minLength: 0)
            Text(SmileIDResourcesHelper.localizedString(for: instruction))
                .font(SmileID.theme.header2)
                .foregroundColor(SmileID.theme.onDark)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            if let message = message {
                Text(message)
                    .multilineTextAlignment(.center)
                    .font(SmileID.theme.header5)
                    .foregroundColor(SmileID.theme.onDark)
            }
        }
        .padding(20)
    }
}
