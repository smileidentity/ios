import SwiftUI

struct DocumentOverlayView: View {
    let aspectRatio: Double
    let borderColor: UIColor

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                TransparentRectangleView(
                    transparentRectSize: CGSize(
                        width: geometry.size.width,
                        height: geometry.size.height / aspectRatio
                    ),
                    borderColor: borderColor
                )
            }
        }
    }
}
