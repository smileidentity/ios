import SmileID
import SwiftUI

typealias OnIdTypeSelectedCallback = (
    _ countryCode: String,
    _ idType: String,
    _ captureBothSides: Bool
) -> Void

private let othersIdType = IdType(
    code: "",
    example: ["My document is not listed"],
    hasBack: true,
    name: "Others"
)

struct DocumentVerificationIdTypeSelector: View {
    let jobType: JobType
    let onIdTypeSelected: OnIdTypeSelectedCallback

    @ObservedObject private var viewModel: DocumentSelectorViewModel

    @State private var selectedCountry: ValidDocument?
    private var idTypesForCountry: [IdType]? { selectedCountry?.idTypes }

    init(jobType: JobType, onIdTypeSelected: @escaping OnIdTypeSelectedCallback) {
        self.jobType = jobType
        self.onIdTypeSelected = onIdTypeSelected
        viewModel = DocumentSelectorViewModel(jobType: jobType)
    }

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
                    RadioGroupSelector(
                        title: "Select ID Type",
                        items: idTypesForCountry,
                        itemDisplayName: { $0.name },
                        initialSelection: jobType == .documentVerification ? othersIdType : nil,
                        onItemSelected: { idType in
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
    let onCountrySelected: (ValidDocument?) -> Void

    @State private var query: String
    private var filteredCountries: [ValidDocument] {
        countries.filter { country in
            query.isEmpty || country.country.name.localizedCaseInsensitiveContains(query)
        }
    }

    init(
        countries: [ValidDocument],
        selectedCountry: String?,
        onCountrySelected: @escaping (ValidDocument?) -> Void
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
                            .foregroundColor(SmileID.theme.accent)
                        Spacer()
                        Text(selectedCountry)
                            .foregroundColor(SmileID.theme.accent)
                            .onTapGesture { onCountrySelected(nil) }
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

            if selectedCountry == nil {
                List(filteredCountries) { country in
                    Button(
                        action: { onCountrySelected(country) },
                        label: {
                            Text(country.country.name)
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
struct CountrySelectorUnselected_Previews: PreviewProvider {
    static var previews: some View {
        CountrySelector(
            countries: [
                ValidDocument(
                    country: Country(code: "us", continent: "NA", name: "United States"),
                    idTypes: [
                        IdType(code: "id1", example: [], hasBack: true, name: "ID 1"),
                        IdType(code: "id2", example: [], hasBack: false, name: "ID 2"),
                        IdType(code: "id3", example: [], hasBack: true, name: "ID 3")
                    ]
                ),
                ValidDocument(
                    country: Country(code: "ca", continent: "NA", name: "Canada"),
                    idTypes: [
                        IdType(code: "id1", example: [], hasBack: true, name: "ID 1"),
                        IdType(code: "id2", example: [], hasBack: false, name: "ID 2"),
                        IdType(code: "id3", example: [], hasBack: true, name: "ID 3")
                    ]
                )
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
