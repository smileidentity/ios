import SwiftUI

struct FaceShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.size.width
        let height = rect.size.height
        path.move(to: CGPoint(x: 0.01707 * width, y: 0.36745 * height))
        path.addCurve(
            to: CGPoint(x: 0.07073 * width, y: 0.20499 * height),
            control1: CGPoint(x: 0.01951 * width, y: 0.33988 * height),
            control2: CGPoint(x: 0.0252 * width, y: 0.26979 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.50041 * width, y: 0.01173 * height),
            control1: CGPoint(x: 0.15081 * width, y: 0.09003 * height),
            control2: CGPoint(x: 0.31382 * width, y: 0.01173 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.98333 * width, y: 0.36745 * height),
            control1: CGPoint(x: 0.76829 * width, y: 0.01173 * height),
            control2: CGPoint(x: 0.98333 * width, y: 0.17038 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.95528 * width, y: 0.55367 * height),
            control1: CGPoint(x: 0.98333 * width, y: 0.41437 * height),
            control2: CGPoint(x: 0.96423 * width, y: 0.51378 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.91504 * width, y: 0.68299 * height),
            control1: CGPoint(x: 0.94513 * width, y: 0.59727 * height),
            control2: CGPoint(x: 0.93169 * width, y: 0.64044 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.50041 * width, y: 0.98768 * height),
            control1: CGPoint(x: 0.83943 * width, y: 0.86188 * height),
            control2: CGPoint(x: 0.6622 * width, y: 0.98768 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.08537 * width, y: 0.68475 * height),
            control1: CGPoint(x: 0.28293 * width, y: 0.98768 * height),
            control2: CGPoint(x: 0.12967 * width, y: 0.78387 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.04268 * width, y: 0.5522 * height),
            control1: CGPoint(x: 0.06463 * width, y: 0.63783 * height),
            control2: CGPoint(x: 0.04593 * width, y: 0.56364 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.01707 * width, y: 0.36745 * height),
            control1: CGPoint(x: 0.0252 * width, y: 0.4824 * height),
            control2: CGPoint(x: 0.01179 * width, y: 0.43079 * height)
        )
        path.closeSubpath()
        return path
    }
}

private struct FaceShape_Previews: PreviewProvider {
    static var previews: some View {
        FaceShape()
    }
}
