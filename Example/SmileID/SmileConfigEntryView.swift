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
            // textField is defined as a getter for compatibility with the #available macro. An
            // alternative would be to use the new Swift feature of if-expressions, but our CI
            // doesn't support Xcode 15 just yet.
            var textField: AnyView {
                if #available(iOS 16.0, *) {
                    return AnyView(
                        TextField(
                            "Paste your Smile Config from the Portal here",
                            text: $smileConfigTextFieldValue,
                            axis: .vertical
                        )
                        .textInputAutocapitalization(.none)
                        .lineLimit(10, reservesSpace: true)
                    )
                } else {
                    return AnyView(
                        TextField(
                            "Paste your Smile Config from the Portal here",
                            text: $smileConfigTextFieldValue
                        )
                        .lineLimit(10)
                    )
                }
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
            
            Button(
                action: { onNewSmileConfig(smileConfigTextFieldValue) },
                label: {
                    Text("Apply config")
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
        }
        .background(SmileID.theme.backgroundLightest.ignoresSafeArea())
    }
}

private struct SmileConfigEntryView_Previews: PreviewProvider {
    static var previews: some View {
        SmileConfigEntryView { _ in }
    }
}
