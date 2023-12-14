import Foundation
import SwiftUI

public struct AspectRatioRoundedRectangle: Shape {
    var aspectRatio: CGFloat
    var cornerRadius: CGFloat

    public func path(in rect: CGRect) -> Path {
        // Calculate the target size maintaining the aspect ratio
        let targetSize: CGSize
        let rectAspectRatio = rect.width / rect.height

        if rectAspectRatio > aspectRatio {
            // Rect is wider than desired, adjust width
            let width = rect.height * aspectRatio
            let xOffset = (rect.width - width) / 2
            targetSize = CGSize(width: width, height: rect.height)
            return RoundedRectangle(cornerRadius: cornerRadius)
                .path(in: CGRect(origin: CGPoint(x: xOffset, y: 0), size: targetSize))
        } else {
            // Rect is taller than desired, adjust height
            let height = rect.width / aspectRatio
            let yOffset = (rect.height - height) / 2
            targetSize = CGSize(width: rect.width, height: height)
            return RoundedRectangle(cornerRadius: cornerRadius)
                .path(in: CGRect(origin: CGPoint(x: 0, y: yOffset), size: targetSize))
        }
    }
}
