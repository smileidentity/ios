import SwiftUI

struct SelfiePreviewView: View {
    var image: UIImage

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(height: 480)
            .clipShape(.rect(cornerRadius: 40))
    }
}
