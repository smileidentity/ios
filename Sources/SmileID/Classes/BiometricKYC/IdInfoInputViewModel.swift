class IdInfoInputViewModel: ObservableObject {
    // MARK: - Input Properties
    private let selectedCountry: String
    private let selectedIdType: String

    // MARK: - UI Properties
    @Published var inputs: [RequiredField: String] = [:]

    // MARK: - Other Properties
    var isContinueEnabled: Bool { inputs.values.allSatisfy { !$0.isEmpty } }

    var currentIdInfo: IdInfo {
        IdInfo(
            country: selectedCountry,
            idType: selectedIdType,
            idNumber: inputs[.idNumber],
            firstName: inputs[.firstName],
            lastName: inputs[.lastName],
            dob: inputs[.dateOfBirth],
            bankCode: inputs[.bankCode],
            entered: true
        )
    }

    init(
        selectedCountry: String,
        selectedIdType: String,
        requiredFields: [RequiredField]
    ) {
        self.selectedCountry = selectedCountry
        self.selectedIdType = selectedIdType

        // We've already asked for these fields as input on the ID Selection screen
        let ignoredFields: [RequiredField] = [
            .country,
            .idType,
            .userId,
            .jobId,
        ]
        requiredFields
            .filter { !ignoredFields.contains($0) }
            .forEach { inputs[$0] = "" }
    }
}

/// An extension to RequiredField which provides a mapping to the input field label and keyboard
// type
extension RequiredField {
    struct InputField {
        let key: RequiredField
        let label: String
        let keyboardType: UIKeyboardType
    }
    var inputField: InputField {
        switch self {
        case .idNumber:
            return InputField(key: self, label: "IdInfo.IdNumber", keyboardType: .asciiCapable)
        case .firstName:
            return InputField(key: self, label: "IdInfo.FirstName", keyboardType: .default)
        case .lastName:
            return InputField(key: self, label: "IdInfo.LastName", keyboardType: .default)
        case .dateOfBirth:
            return InputField(key: self, label: "IdInfo.DOB", keyboardType: .default)
        case .day:
            return InputField(key: self, label: "IdInfo.Day", keyboardType: .numberPad)
        case .month:
            return InputField(key: self, label: "IdInfo.Month", keyboardType: .numberPad)
        case .year:
            return InputField(key: self, label: "IdInfo.Year", keyboardType: .numberPad)
        case .bankCode:
            return InputField(key: self, label: "IdInfo.BankCode", keyboardType: .numberPad)
        case .citizenship:
            return InputField(key: self, label: "IdInfo.Citizenship", keyboardType: .default)
        default:
            return InputField(key: self, label: self.rawValue, keyboardType: .default)
        }
    }
}
