import SwiftUI

public struct SearchableDropdownSelector<T: Identifiable>: View {
    let items: [T]
    let selectedItem: T?
    let itemDisplayName: (T) -> String
    let onItemSelected: (T?) -> Void

    @State private var query: String
    private var filteredItems: [T] {
        items.filter { item in
            query.isEmpty || itemDisplayName(item).localizedCaseInsensitiveContains(query)
        }
    }

    public init(
        items: [T],
        selectedItem: T?,
        itemDisplayName: @escaping (T) -> String,
        onItemSelected: @escaping (T?) -> Void
    ) {
        self.items = items
        self.selectedItem = selectedItem
        self.itemDisplayName = itemDisplayName
        self.onItemSelected = onItemSelected
        _query = State(initialValue: selectedItem.map(itemDisplayName) ?? "")
    }

    public var body: some View {
        VStack {
            ZStack {
                if let selectedItem = selectedItem {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(SmileID.theme.accent)
                        Spacer()
                        Text(itemDisplayName(selectedItem))
                            .foregroundColor(SmileID.theme.accent)
                            .onTapGesture { onItemSelected(nil) }
                        Spacer()
                        Image(systemName: "arrowtriangle.down.circle.fill")
                            .foregroundColor(SmileID.theme.accent)
                    }
                } else {
                    ZStack(alignment: .leading) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(SmileID.theme.accent)
                        TextField("Search", text: $query)
                            .autocapitalization(.words)
                            .disableAutocorrection(true)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()

            if selectedItem == nil {
                List(filteredItems) { item in
                    Button(
                        action: { onItemSelected(item) },
                        label: {
                            Text(itemDisplayName(item))
                                .multilineTextAlignment(.leading)
                                .foregroundColor(SmileID.theme.accent)
                        }
                    )
                }
            }
        }
    }
}

@available(iOS 14.0, *)
private struct SearchableDropdownSelectorUnselected_Previews: PreviewProvider {
    static var previews: some View {
        SearchableDropdownSelector(
            items: [
                ValidDocument(
                    country: Country(code: "us", continent: "NA", name: "United States"),
                    idTypes: []
                ),
                ValidDocument(
                    country: Country(code: "ca", continent: "NA", name: "Canada"),
                    idTypes: []
                )
            ],
            selectedItem: nil,
            itemDisplayName: { $0.country.name },
            onItemSelected: { _ in }
        )
    }
}

@available(iOS 14.0, *)
private struct SearchableDropdownSelectorSelected_Previews: PreviewProvider {
    static var previews: some View {
        let first = ValidDocument(
            country: Country(code: "us", continent: "NA", name: "United States"),
            idTypes: []
        )
        SearchableDropdownSelector(
            items: [
                first,
                ValidDocument(
                    country: Country(code: "ca", continent: "NA", name: "Canada"),
                    idTypes: []
                )
            ],
            selectedItem: first,
            itemDisplayName: { $0.country.name },
            onItemSelected: { _ in }
        )
    }
}
