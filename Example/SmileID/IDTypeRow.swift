import SwiftUI
import SmileID

struct IDTypeRow: View {
    let idType: IdType
    @Binding var isSelected: Bool
    var body: some View {
        Button(
            action: { isSelected.toggle() },
            label: {
                HStack {
                    Text(idType.name)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(SmileID.theme.accent)
                        .padding()
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle" : "circle")
                        .foregroundColor(SmileID.theme.accent)
                        .padding()
                }
                    .frame(height: 48)
            }
        )
    }
}
