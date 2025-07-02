import SmileID
import SwiftUI

struct NavigationBar: View {
  let backButtonHandler: () -> Void
  let title: String
  var body: some View {
    ZStack {
      HStack {
        Button(
          action: backButtonHandler,
          label: { Image(uiImage: SmileIDResourcesHelper.ArrowLeft) }).padding(.leading)
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
