import SwiftUI

struct DocumentShapedBoundingBox: View {
    let aspectRatio: Double
    let borderColor: Color

    var body: some View {
        ZStack {
            Rectangle().foregroundColor(Color.black.opacity(0.5))
            Rectangle()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(aspectRatio, contentMode: .fit)
                .blendMode(.destinationOut)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(borderColor, lineWidth: 4))
                .padding(32)
        }
    }
}
