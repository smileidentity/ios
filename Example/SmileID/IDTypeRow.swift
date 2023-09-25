import SwiftUI
import SmileID

struct IDTypeRow: View {
    var idType: IdType
    var body: some View {
        Button(action: <#T##() -> Void#>, label: {
            HStack {
                Text(idType.name)
                    .multilineTextAlignment(.leading)
                    .padding()
                Spacer()
                Image(systemName: "circle")
                    .padding()
            }
            .frame(height: 59)
        })
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        IDTypeRow(idType: IdType(code: "", example: [String](), hasBack: true, name: "Passport"))
    }
}
