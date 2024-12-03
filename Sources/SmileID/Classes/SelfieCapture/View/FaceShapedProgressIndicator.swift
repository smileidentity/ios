import Foundation
import SwiftUI

struct FaceShapedProgressIndicator: View {
    let progress: Double
    private let strokeWidth = 10
    private let faceShape = FaceShape().scale(x: 0.8, y: 0.55).offset(y: -50)
    private let bgColor = Color.white.opacity(0.8)
    var body: some View {
        bgColor
            .cutout(faceShape)
            .overlay(faceShape.stroke(SmileID.theme.accent.opacity(0.4), lineWidth: 10))
            .overlay(
                // TODO: Make this fill from bottom to top, symmetrically
                faceShape
                    .trim(from: 0, to: progress)
                    .stroke(
                        SmileID.theme.success,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .animation(.easeInOut, value: progress)
            )
            .edgesIgnoringSafeArea(.all)
            .preferredColorScheme(.light)
    }
}
