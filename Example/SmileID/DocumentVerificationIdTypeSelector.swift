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
        if #available(iOS 17.1, *) {
            Self._printChanges()
        } else {
            // Fallback on earlier versions
        }
        return VStack {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage).foregroundColor(.red)
            } else if viewModel.idTypes.isEmpty {
                ActivityIndicator(isAnimating: true).padding()
                Text("Loading Documents…")
                    .font(SmileID.theme.body)
                    .foregroundColor(SmileID.theme.onLight)
            } else {
                SearchableDropdownSelector(
                    items: viewModel.idTypes,
                    selectedItem: selectedCountry,
                    itemDisplayName: { $0.country.name },
                    onItemSelected: {
                        selectedCountry = $0
                    }
                )

                if let idTypesForCountry = idTypesForCountry {
                    RadioGroupSelector(
                        title: "Select ID Type",
                        items: idTypesForCountry,
                        initialSelection: jobType == .documentVerification ? othersIdType : nil,
                        itemDisplayName: { $0.name },
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
        .onAppear {
            Task {
                try await self.viewModel.getServices()
            }
        }
    }
}
