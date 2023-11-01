import SmileID
import SwiftUI

struct SmileConfigEntryView: View {
    private let errorMessage: String?
    private let onNewSmileConfig: (_ newConfig: String) -> Void

    init(
        errorMessage: String? = nil,
        onNewSmileConfig: @escaping (_ newConfig: String) -> Void
    ) {
        self.errorMessage = errorMessage
        self.onNewSmileConfig = onNewSmileConfig
    }

    @State private var smileConfigTextFieldValue = ""
    var body: some View {
        VStack {
            Spacer()
            let textField: AnyView
            if #available(iOS 16.0, *) {
                textField = AnyView(
                    TextField(
                        "Paste your Smile Config from the Portal here",
                        text: $smileConfigTextFieldValue,
                        axis: .vertical
                    )
                        .textInputAutocapitalization(.none)
                        .lineLimit(10, reservesSpace: true)
                )
            } else {
                textField = AnyView(
                    TextField(
                        "Paste your Smile Config from the Portal here",
                        text: $smileConfigTextFieldValue
                    )
                        .lineLimit(10)
                )
            }
            let strokeColor = errorMessage == nil ? SmileID.theme.accent : SmileID.theme.error
            textField
                .autocorrectionDisabled(true)
                .foregroundColor(SmileID.theme.onLight)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 10).stroke(strokeColor, lineWidth: 2)
                )
                .padding()
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(SmileID.theme.error)
                    .padding()
            }

            Spacer()

            Button(
                action: { onNewSmileConfig(smileConfigTextFieldValue) },
                label: {
                    Text("Update Smile Config")
                        .padding()
                        .font(SmileID.theme.button)
                        .frame(maxWidth: .infinity)
                }
            )
                .foregroundColor(SmileID.theme.onDark)
                .background(SmileID.theme.accent)
                .cornerRadius(60)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(.vertical, 2)

            Button(
                action: { print("TODO") },
                label: {
                    Text("Scan QR Code from Portal")
                        .padding()
                        .font(SmileID.theme.button)
                        .frame(maxWidth: .infinity)
                }
            )
                .foregroundColor(SmileID.theme.accent)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 60)
                        .stroke(SmileID.theme.accent, lineWidth: 4)
                )
                .cornerRadius(60)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(.vertical, 2)
        }
    }
}

private struct SmileConfigEntryView_Previews: PreviewProvider {
    static var previews: some View {
        SmileConfigEntryView { _ in }
    }
}
