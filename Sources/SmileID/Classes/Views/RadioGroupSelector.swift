import SwiftUI

public struct RadioGroupSelector<T>: View where T: Identifiable & Equatable {
    let title: String
    let items: [T]
    let itemDisplayName: (T) -> String
    let onItemSelected: (T) -> Void

    @State private var selectedItem: T?

    public init(
        title: String,
        items: [T],
        initialSelection: T? = nil,
        itemDisplayName: @escaping (T) -> String,
        onItemSelected: @escaping (T) -> Void
    ) {
        self.title = title
        self.items = items
        self.itemDisplayName = itemDisplayName
        self.onItemSelected = onItemSelected
        _selectedItem = State(initialValue: initialSelection)
    }

    public var body: some View {
        VStack {
            Text(title)
                .font(SmileID.theme.header2)
                .foregroundColor(SmileID.theme.onLight)
                .fontWeight(.bold)
                .padding(16)

            List(items) { item in
                HStack {
                    Text(itemDisplayName(item))
                        .foregroundColor(SmileID.theme.accent)
                    Spacer()
                    Image(systemName: selectedItem == item ? "checkmark.circle" : "circle")
                        .foregroundColor(SmileID.theme.accent)
                        .padding()
                }
                    .contentShape(Rectangle())
                    .onTapGesture { selectedItem = item }
            }

            Spacer()

            // Button is always enabled, because we can default to Others
            let isDisabled = selectedItem == nil
            Button(
                action: {
                    // This should never be nil, because the button is disabled if it is
                    if let selectedItem = selectedItem {
                        onItemSelected(selectedItem)
                    } else {
                        print("[ERROR][RadioGroupSelectionScreen] Unexpectedly selected nil item")
                    }
                },
                label: {
                    Text(SmileIDResourcesHelper.localizedString(for: "Confirmation.Continue"))
                        .padding(16)
                        .font(SmileID.theme.button)
                        .frame(maxWidth: .infinity)
                }
            )
                .disabled(isDisabled)
                .background(isDisabled ? Color.gray : SmileID.theme.accent)
                .foregroundColor(SmileID.theme.onDark)
                .cornerRadius(60)
                .frame(maxWidth: .infinity)
                .padding()
                .preferredColorScheme(.light)
        }
    }
}

private struct RadioGroupSelector_Previews: PreviewProvider {
    static var previews: some View {
        let first = IdType(code: "id1", example: [], hasBack: true, name: "ID 1")
        RadioGroupSelector(
            title: "Select ID Type",
            items: [
                first,
                IdType(code: "id2", example: [], hasBack: false, name: "ID 2"),
                IdType(code: "id3", example: [], hasBack: true, name: "ID 3")
            ],
            initialSelection: first,
            itemDisplayName: { $0.name },
            onItemSelected: { _ in }
        )
    }
}
