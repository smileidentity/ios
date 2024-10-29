import SwiftUI

struct UserInstructionsView: View {
    var instruction: String

    var body: some View {
        Text(SmileIDResourcesHelper.localizedString(for: instruction))
            .font(SmileID.theme.header2)
            .foregroundColor(SmileID.theme.onDark)
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .minimumScaleFactor(0.8)
            .padding(20)
    }
}
