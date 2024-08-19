import SwiftUI

struct DocumentShapedBoundingBox: View {
    private let aspectRatio: Double
    private let borderColor: Color
    private let cutoutShape: ScaledShape<AspectRatioRoundedRectangle>

    init(
        aspectRatio: Double,
        borderColor: Color
    ) {
        self.aspectRatio = aspectRatio
        self.borderColor = borderColor
        cutoutShape = AspectRatioRoundedRectangle(aspectRatio: aspectRatio, cornerRadius: 16)
            .scale(0.85)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                // We use cutout here instead of .blendMode(.destinationOut) because that causes
                // issues on iOS 14 devices
                .cutout(cutoutShape)
                .overlay(cutoutShape.stroke(borderColor, lineWidth: 4))
        }.preferredColorScheme(.light)
    }
}
