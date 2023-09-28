import SwiftUI
import SmileID

struct IdTypeListView: View {
    @EnvironmentObject var router: Router<NavigationDestination>
    let document: ValidDocument
    var homeViewModel: HomeViewModel
    @State private var selectedIdType: IdType?
    var body: some View {
        VStack {
            List(document.idTypes) { idType in
                IDTypeRow(
                    idType: idType,
                    isSelected: Binding<Bool>(
                        get: { selectedIdType == idType },
                        set: { _ in self.selectedIdType = idType }
                    )
                )
            }

            SmileButton(
                style: .primary,
                title: "Continue",
                backgroundColor: SmileID.theme.accent,
                clicked: {
                    if let selectedIdType = selectedIdType {
                        router.push(.documentCaptureScreen(
                            countryCode: document.country.code,
                            documentType: selectedIdType.code,
                            captureBothSides: selectedIdType.hasBack,
                            delegate: homeViewModel
                        ))
                    }
                }
            )
                .padding()
                .disabled(selectedIdType == nil)
        }
            .padding(.top, 50)
            .overlay(NavigationBar(backButtonHandler: { router.pop() }, title: "Select ID Type"))
    }
}
