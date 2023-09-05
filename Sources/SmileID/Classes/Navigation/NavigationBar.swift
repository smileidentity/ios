import SwiftUI

struct NavigationBar: View {
    var body: some View {
        HStack {
            Image(uiImage: SmileIDResourcesHelper.ArrowLeft)
            Spacer()
        }.frame(height: 40)
    }
}

struct NavigationBar_Previews: PreviewProvider {
    static var previews: some View {
        NavigationBar()
    }
}
