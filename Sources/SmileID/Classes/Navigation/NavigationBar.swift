import SwiftUI

struct NavigationBar: View {
    let backButtonHandler: () -> Void
    var body: some View {
        HStack {
            Button(
                action: backButtonHandler,
                label: { Image(uiImage: SmileIDResourcesHelper.ArrowLeft) }
            ).padding(.leading)
            Spacer()
        }
            .frame(height: 50)
            .frame(maxHeight: .infinity, alignment: .top)
            .preferredColorScheme(.light)
    }
}

private struct NavigationBar_Previews: PreviewProvider {
    static var previews: some View {
        NavigationBar(backButtonHandler: {})
    }
}
