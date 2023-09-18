import SwiftUI

struct IDTypeRow: View {
    @State var idName: String
    var body: some View {
        Text("")
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        IDTypeRow(idName: "Drivers License")
    }
}
