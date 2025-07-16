import SmileID
import SwiftUI

struct EnterUserIDView: View {
  let onContinue: (_ userId: String) -> Void
  @State private var userId: String

  init(
    initialUserId: String = "",
    onContinue: @escaping (String) -> Void
  ) {
    self.onContinue = onContinue
    userId = initialUserId
  }

  var body: some View {
    VStack(spacing: 5) {
      Text("Please enter an enrolled User ID")
        .font(SmileID.theme.header4)
        .foregroundColor(SmileID.theme.onLight)
      VStack {
        SmileTextField(field: $userId, placeholder: "User ID")
          .multilineTextAlignment(.center)

        SmileButton(title: "Continue", clicked: { onContinue(userId) })
          .disabled(userId.isEmpty)
          .padding()
      }
      Spacer()
    }
    .padding(.top, 50)
    .background(SmileID.theme.backgroundLight.ignoresSafeArea())
  }
}

private struct EnterUserIDView_Previews: PreviewProvider {
  static var previews: some View {
    EnterUserIDView(initialUserId: "initialValue") { _ in }
  }
}
