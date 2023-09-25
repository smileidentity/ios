import SwiftUI
import SmileID

struct NavigationBar: View {
    var backButtonHandler: (() -> Void)
    var title: String
    var body: some View {
        ZStack {
            HStack {
                Button {
                    backButtonHandler()
                } label: {
                    Image(uiImage: SmileIDResourcesHelper.ArrowLeft)
                }.padding(.leading)
                Spacer()
            }
            Text(title)
                .multilineTextAlignment(.center)
                .foregroundColor(SmileID.theme.accent)
        }
        .frame(height: 50)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
