import SmileID
import SwiftUI

struct DocumentVerificationIdTypeSelector: View {
    let onIdTypeSelected: (_ countryCode: String, _ idType: String, _ captureBothSides: Bool) -> ()

    @ObservedObject private var viewModel = DocumentSelectorViewModel()

    @State private var selectedCountry: ValidDocument?
    private var idTypesForCountry: [IdType]? { selectedCountry?.idTypes }

    var body: some View {
        VStack {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage).foregroundColor(.red)
            } else if viewModel.idTypes.isEmpty {
                ActivityIndicator(isAnimating: true).padding()
                Text("Loading Documents…")
                    .font(SmileID.theme.body)
                    .foregroundColor(SmileID.theme.onLight)
            } else {
                CountrySelector(
                    countries: viewModel.idTypes,
                    selectedCountry: selectedCountry?.country.name,
                    onCountrySelected: { selectedCountry = $0 }
                )

                if let idTypesForCountry = idTypesForCountry {
                    IdTypeSelector(
                        idTypesForCountry: idTypesForCountry,
                        onIdTypeSelected: { idType in
                            onIdTypeSelected(
                                selectedCountry!.country.code,
                                idType.code,
                                idType.hasBack
                            )
                        }
                    )
                }
            }
        }
    }
}

private struct CountrySelector: View {
    let countries: [ValidDocument]
    let selectedCountry: String?
    let onCountrySelected: (ValidDocument?) -> ()

    @State private var query: String
    private var filteredCountries: [ValidDocument] {
        countries.filter { country in
            query.isEmpty || country.country.name.localizedCaseInsensitiveContains(query)
        }
    }

    init(
        countries: [ValidDocument],
        selectedCountry: String?,
        onCountrySelected: @escaping (ValidDocument?) -> ()
    ) {
        self.countries = countries
        self.selectedCountry = selectedCountry
        self.onCountrySelected = onCountrySelected
        _query = State(initialValue: selectedCountry ?? "")
    }

    var body: some View {
        VStack {
            ZStack {
                if let selectedCountry = selectedCountry {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                        Spacer()
                        Text(selectedCountry)
                            .foregroundColor(SmileID.theme.accent)
                            .onTapGesture { onCountrySelected(nil) }
                        Spacer()
                        Image(systemName: "arrowtriangle.down.circle.fill")
                    }
                } else {
                    ZStack(alignment: .leading) {
                        Image(systemName: "magnifyingglass")
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

            if selectedCountry == nil {
                List(filteredCountries) { country in
                    Button(action: { onCountrySelected(country) }) {
                        Text(country.country.name)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(SmileID.theme.accent)
                    }
                }
            }
        }
    }
}

private let othersIdType = IdType(code: "", example: [], hasBack: true, name: "Others")

private struct IdTypeSelector: View {
    let idTypesForCountry: [IdType]
    let onIdTypeSelected: (IdType) -> ()

    @State private var selectedIdType: IdType?

    var body: some View {
        VStack {
            Text("Select ID Type")
                .font(SmileID.theme.header2)
                .foregroundColor(SmileID.theme.onLight)
                .fontWeight(.bold)
                .padding(16)

            List(idTypesForCountry) { idType in
                HStack {
                    Text(idType.name)
                    Spacer()
                    Image(systemName: selectedIdType == idType ? "checkmark.circle" : "circle")
                        .foregroundColor(SmileID.theme.accent)
                        .padding()
                }
                    .contentShape(Rectangle())
                    .onTapGesture { selectedIdType = idType }
            }

            Spacer()

            // Button is always enabled, because we can default to Others
            Button(action: { onIdTypeSelected(selectedIdType ?? othersIdType) }) {
                Text("Continue")
                    .padding(16)
                    .font(SmileID.theme.button)
                    .frame(maxWidth: .infinity)
            }
                .background(SmileID.theme.accent)
                .foregroundColor(SmileID.theme.onDark)
                .cornerRadius(60)
                .frame(maxWidth: .infinity)
                .padding()
        }
    }
}

@available(iOS 14.0, *)
struct IdTypeSelector_Previews: PreviewProvider {
    static var previews: some View {
        IdTypeSelector(
            idTypesForCountry: [
                IdType(code: "id1", example: [], hasBack: true, name: "ID 1"),
                IdType(code: "id2", example: [], hasBack: false, name: "ID 2"),
                IdType(code: "id3", example: [], hasBack: true, name: "ID 3"),
            ],
            onIdTypeSelected: { _ in }
        )
    }
}

@available(iOS 14.0, *)
struct CountrySelectorUnselected_Previews: PreviewProvider {
    static var previews: some View {
        CountrySelector(
            countries: [
                ValidDocument(
                    country: Country(code: "us", continent: "NA", name: "United States"),
                    idTypes: [
                        IdType(code: "id1", example: [], hasBack: true, name: "ID 1"),
                        IdType(code: "id2", example: [], hasBack: false, name: "ID 2"),
                        IdType(code: "id3", example: [], hasBack: true, name: "ID 3"),
                    ]
                ),
                ValidDocument(
                    country: Country(code: "ca", continent: "NA", name: "Canada"),
                    idTypes: [
                        IdType(code: "id1", example: [], hasBack: true, name: "ID 1"),
                        IdType(code: "id2", example: [], hasBack: false, name: "ID 2"),
                        IdType(code: "id3", example: [], hasBack: true, name: "ID 3"),
                    ]
                ),
            ],
            selectedCountry: nil,
            onCountrySelected: { _ in }
        )
    }
}

@available(iOS 14.0, *)
struct CountrySelectorSelected_Previews: PreviewProvider {
    static var previews: some View {
        CountrySelector(
            countries: [],
            selectedCountry: "United States",
            onCountrySelected: { _ in }
        )
    }
}
