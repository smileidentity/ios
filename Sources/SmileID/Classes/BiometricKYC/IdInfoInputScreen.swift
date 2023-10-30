import SwiftUI

/// Allows user to enter ID info. Requires that the user has already selected a country and ID type.
/// It does not allow the entry of any whitespace. Dates are selected using a `DatePicker`, and
/// everything else using a `TextField`
///
/// - Parameters:
///  - selectedCountry: The country code of the selected country
///  - selectedIdType: The ID type code of the selected ID type
///  - header: The header to display at the top of the screen
///  - requiredFields: The fields that the user must enter
///  - onResult: The callback to invoke when the user taps the Continue button. The result will be
///  delivered as an `IdInfo` object.
struct IdInfoInputScreen: View {
    let header: String
    let onResult: (IdInfo) -> Void
    let dateFormatter = DateFormatter()
    @ObservedObject var viewModel: IdInfoInputViewModel

    init(
        selectedCountry: String,
        selectedIdType: String,
        header: String,
        requiredFields: [RequiredField],
        onResult: @escaping (IdInfo) -> Void
    ) {
        self.header = header
        self.onResult = onResult
        dateFormatter.dateFormat = "yyyy-MM-dd"
        viewModel = IdInfoInputViewModel(
            selectedCountry: selectedCountry,
            selectedIdType: selectedIdType,
            requiredFields: requiredFields
        )
    }

    var body: some View {
        VStack(alignment: .center) {
            Form {
                Section(
                    header: Text(header)
                        .font(SmileID.theme.header2)
                        .foregroundColor(SmileID.theme.onLight)
                        .padding(.vertical, 8)
                ) {
                    let sortedKeys = viewModel.inputs.keys.sorted(by: RequiredField.sorter)
                    ForEach(sortedKeys, id: \.self) { key in
                        let localizedLabel = SmileIDResourcesHelper.localizedString(
                            for: key.inputField.label
                        )
                        VStack(alignment: .leading) {
                            if key == .dateOfBirth {
                                let valueBinding = Binding<Date>(
                                    get: {
                                        let value = viewModel.inputs[key] ?? ""
                                        return dateFormatter.date(from: value) ?? Date()
                                    },
                                    set: {
                                        viewModel.inputs[key] = dateFormatter.string(from: $0)
                                    }
                                )
                                DatePicker(
                                    localizedLabel,
                                    selection: valueBinding,
                                    in: ...Date(),
                                    displayedComponents: [.date]
                                )
                                    .font(SmileID.theme.button)
                                    .foregroundColor(SmileID.theme.onLight)
                                    .padding(4)
                            } else {
                                let valueBinding = Binding<String>(
                                    get: { viewModel.inputs[key] ?? "Error" },
                                    set: { newValue in
                                        viewModel.inputs[key] = newValue.filter { !$0.isWhitespace }
                                    }
                                )
                                Text(localizedLabel)
                                    .font(SmileID.theme.button)
                                    .foregroundColor(SmileID.theme.onLight)
                                    .padding(4)
                                TextField(localizedLabel, text: valueBinding)
                                    .keyboardType(key.inputField.keyboardType)
                                    .disableAutocorrection(true)
                                    .autocapitalization(.none)
                                    .textFieldStyle(.roundedBorder)
                                    .foregroundColor(SmileID.theme.onLight)
                                    .padding(4)
                            }
                        }
                    }
                }
            }
                .background(SmileID.theme.backgroundLight)

            Button(
                action: { onResult(viewModel.currentIdInfo) },
                label: {
                    Text(SmileIDResourcesHelper.localizedString(for: "Confirmation.Continue"))
                        .padding(16)
                        .font(SmileID.theme.button)
                        .frame(maxWidth: .infinity)
                }
            )
                .disabled(!viewModel.isContinueEnabled)
                .background(!viewModel.isContinueEnabled ? Color.gray : SmileID.theme.accent)
                .foregroundColor(SmileID.theme.onDark)
                .cornerRadius(60)
                .frame(maxWidth: .infinity)
                .padding()
        }.frame(maxWidth: .infinity)
    }
}

@available(iOS 14.0, *)
private struct IdInfoInputScreen_Previews: PreviewProvider {
    static var previews: some View {
        IdInfoInputScreen(
            selectedCountry: "US",
            selectedIdType: "Driver's License",
            header: "Enter ID Info",
            requiredFields: [.idNumber, .firstName, .lastName, .dateOfBirth, .bankCode],
            onResult: { _ in }
        )
    }
}
