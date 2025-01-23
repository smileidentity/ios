import SwiftUI

public struct SearchableDropdownSelector<T: Identifiable>: View {
    let items: [T]
    let selectedItem: T?
    let itemDisplayName: (T) -> String
    let onItemSelected: (T?) -> Void

    @Binding private var query: String
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
        self._query = selectedItem.map(itemDisplayName) ?? "" // State(initialValue: selectedItem.map(itemDisplayName) ?? "")
    }

    public var body: some View {
        if #available(iOS 17.1, *) {
            Self._printChanges()
        } else {
            // Fallback on earlier versions
        }
        return VStack {
            ZStack {
                if let selectedItem = selectedItem {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(SmileID.theme.accent)
                        Spacer()
                        Text(itemDisplayName(selectedItem))
                            .foregroundColor(SmileID.theme.accent)
                        Spacer()
                        Image(systemName: "arrowtriangle.down.circle.fill")
                            .foregroundColor(SmileID.theme.accent)
                    }
                    .contentShape(.rect)
                    .onTapGesture {
                        onItemSelected(nil)
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
                        action: {
                            onItemSelected(item)
                        },
                        label: {
                            Text(itemDisplayName(item))
                                .multilineTextAlignment(.leading)
                                .foregroundColor(SmileID.theme.accent)
                        }
                    )
                }
            }
        }.preferredColorScheme(.light)
    }
}

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
