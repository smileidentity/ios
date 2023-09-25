import SwiftUI
import SmileID

struct IdTypeListView: View {
    @EnvironmentObject var router: Router<NavigationDestination>
    var document: ValidDocument
    var body: some View {
        VStack {
            List(document.idTypes) { idType in
                IDTypeRow(idType: idType)
            }

            SmileButton(style: .primary, 
                        title: "Continue",
                        backgroundColor: SmileID.theme.accent,
                        clicked: {

            }).padding()
        }
        .padding(.top, 50)
        .overlay(NavigationBar(backButtonHandler: { router.pop() }, title: "Select ID Type"))
    }
}
