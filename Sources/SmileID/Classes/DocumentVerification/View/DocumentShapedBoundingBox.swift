import SwiftUI

struct DocumentShapedBoundingBox: View {
    let aspectRatio: Double
    let borderColor: Color
    let cornerRadius = RoundedRectangle(cornerRadius: 16)

    var body: some View {
        ZStack {
            Rectangle().foregroundColor(Color.black.opacity(0.7))
            cornerRadius
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(aspectRatio, contentMode: .fit)
                .blendMode(.destinationOut)
                .overlay(cornerRadius.stroke(borderColor, lineWidth: 4))
                .padding(32)
        }
    }
}
