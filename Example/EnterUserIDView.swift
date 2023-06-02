import SwiftUI

struct EnterUserIDView: View {
    var userId: String
    var body: some View {
        VStack{
            Text("Please enter an enrolled UserID")
            TextField(userId)
            Button("Continue")
        }
    }
}

struct EnterUserIDView_Previews: PreviewProvider {
    static var previews: some View {
        EnterUserIDView(userId: "")
    }
}
