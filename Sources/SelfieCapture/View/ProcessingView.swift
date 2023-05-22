import SwiftUI

struct ProcessingView: View {
    var body: some View {

        VStack(spacing: 20) {
            InfiniteProgressBar()
                .frame(width: 60)
            Image(uiImage: SmileIDResourcesHelper.FaceOutline)
            VStack(spacing: 16) {
                Text(SmileIDResourcesHelper.localizedString(for: "Confirmation.Processing"))
                    .multilineTextAlignment(.center)
                    .font(SmileIdentity.theme.header4)
                    .foregroundColor(SmileIdentity.theme.accent)

                Text(SmileIDResourcesHelper.localizedString(for: "Confirmation.Time"))
                    .multilineTextAlignment(.center)
                    .font(SmileIdentity.theme.header5)
                    .foregroundColor(SmileIdentity.theme.tertiary)
                .lineSpacing(1.3)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 80)
        }
            .padding()
            .background(SmileIdentity.theme.backgroundMain)
            .cornerRadius(20)
            .shadow(radius: 20)
    }
}

struct ProcessingView_Previews: PreviewProvider {
    static var previews: some View {
        ProcessingView()
    }
}
