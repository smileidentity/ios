import SwiftUI
import SmileID

struct CountryRow: View {
    var document: ValidDocument
    var action: (ValidDocument) -> Void
    var body: some View {
        Button(
            action: { action(document) },
            label: {
                Text(document.country.name)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(SmileID.theme.accent)
            }
        )
    }
}
