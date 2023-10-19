import SwiftUI

struct BvnInputScreen: View {
    let showLoading: Bool
    let showError: Bool
    let supportingText: String
    let errorMessage: String
    let onContinue: (_ bvn: String) -> Void
    @State private var bvn = ""

    public var body: some View {
        VStack(spacing: 24) {
            Text("Enter your BVN Number")
                .multilineTextAlignment(.center)
                .font(SmileID.theme.header1)
                .foregroundColor(SmileID.theme.accent)

            Text("Bank Verification Number")
                .multilineTextAlignment(.center)
                .font(SmileID.theme.header4)
                .foregroundColor(SmileID.theme.tertiary)

            TextField("BVN", text: $bvn)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .textFieldStyle(.roundedBorder)

            if showError {
                Text(supportingText)
                    .multilineTextAlignment(.leading)
                    .font(SmileID.theme.header5)
                    .foregroundColor(SmileID.theme.error)
                    .lineSpacing(1.3)
            } else {
                Text(supportingText)
                    .multilineTextAlignment(.leading)
                    .font(SmileID.theme.header5)
                    .foregroundColor(SmileID.theme.tertiary)
                    .lineSpacing(1.3)
            }

            Spacer()

            Button(
                action: { onContinue(bvn) },
                label: {
                    HStack {
                        if showLoading {
                            ActivityIndicator(isAnimating: true, style: .large)
                                .colorInvert()
                        } else {
                            Text("Continue")
                        }
                    }
                        .padding(14)
                        .font(SmileID.theme.button)
                        .frame(maxWidth: .infinity)
                }
            )
                .background(SmileID.theme.accent)
                .foregroundColor(SmileID.theme.onDark)
                .cornerRadius(60)
                .frame(maxWidth: .infinity)
                .disabled(showLoading || bvn.count != 11)
        }
            .padding()
    }
}


// struct BvnInputScreen_Previews: PreviewProvider {
//     static var previews: some View {
//         BvnInputScreen()
//     }
// }
