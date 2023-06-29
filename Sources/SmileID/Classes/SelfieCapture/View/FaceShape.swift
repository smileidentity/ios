import SwiftUI

struct FaceShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.size.width
        let height = rect.size.height
        path.move(to: CGPoint(x: 0.01707*width, y: 0.36745*height))
        path.addCurve(to: CGPoint(x: 0.07073*width, y: 0.20499*height), control1: CGPoint(x: 0.01951*width, y: 0.33988*height), control2: CGPoint(x: 0.0252*width, y: 0.26979*height))
        path.addCurve(to: CGPoint(x: 0.50041*width, y: 0.01173*height), control1: CGPoint(x: 0.15081*width, y: 0.09003*height), control2: CGPoint(x: 0.31382*width, y: 0.01173*height))
        path.addCurve(to: CGPoint(x: 0.98333*width, y: 0.36745*height), control1: CGPoint(x: 0.76829*width, y: 0.01173*height), control2: CGPoint(x: 0.98333*width, y: 0.17038*height))
        path.addCurve(to: CGPoint(x: 0.95528*width, y: 0.55367*height), control1: CGPoint(x: 0.98333*width, y: 0.41437*height), control2: CGPoint(x: 0.96423*width, y: 0.51378*height))
        path.addCurve(to: CGPoint(x: 0.91504*width, y: 0.68299*height), control1: CGPoint(x: 0.94513*width, y: 0.59727*height), control2: CGPoint(x: 0.93169*width, y: 0.64044*height))
        path.addCurve(to: CGPoint(x: 0.50041*width, y: 0.98768*height), control1: CGPoint(x: 0.83943*width, y: 0.86188*height), control2: CGPoint(x: 0.6622*width, y: 0.98768*height))
        path.addCurve(to: CGPoint(x: 0.08537*width, y: 0.68475*height), control1: CGPoint(x: 0.28293*width, y: 0.98768*height), control2: CGPoint(x: 0.12967*width, y: 0.78387*height))
        path.addCurve(to: CGPoint(x: 0.04268*width, y: 0.5522*height), control1: CGPoint(x: 0.06463*width, y: 0.63783*height), control2: CGPoint(x: 0.04593*width, y: 0.56364*height))
        path.addCurve(to: CGPoint(x: 0.01707*width, y: 0.36745*height), control1: CGPoint(x: 0.0252*width, y: 0.4824*height), control2: CGPoint(x: 0.01179*width, y: 0.43079*height))
        path.closeSubpath()
        return path
    }
}

struct FaceShape_Previews: PreviewProvider {
    static var previews: some View {
       FaceShape()
    }
}


import UIKit

class FaceOverlayViews: UIView {
    var agentMode = false
    var model: SelfieCaptureViewModel?

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let faceWidth = rect.size.width * 0.6
        let faceHeight = faceWidth / 0.7

        context.saveGState()
        context.setFillColor(UIColor.white.withAlphaComponent(0.8).cgColor)
        context.fill(rect)

        let faceShapePath = createFaceShapePath(rect: rect, faceWidth: faceWidth, faceHeight: faceHeight)
        context.addPath(faceShapePath)
        context.setBlendMode(.destinationOut)
        context.fillPath()

        context.addPath(faceShapePath)
        context.setStrokeColor(UIColor.systemBlue.withAlphaComponent(0.4).cgColor)
        context.setLineWidth(10)
        context.strokePath()

        if let model = model {
            let progressPath = createProgressPath(rect: rect, faceWidth: faceWidth, faceHeight: faceHeight, progress: CGFloat(model.progress))
            context.addPath(progressPath)
            context.setStrokeColor(UIColor.systemGreen.cgColor)
            context.setLineWidth(10)
            context.strokePath()
        }

        context.restoreGState()
    }

    private func createFaceShapePath(rect: CGRect, faceWidth: CGFloat, faceHeight: CGFloat) -> CGPath {
        let path = UIBezierPath()
        let width = rect.size.width
        let height = rect.size.height

        path.move(to: CGPoint(x: 0.01707 * width, y: 0.36745 * height))
        path.addCurve(to: CGPoint(x: 0.07073 * width, y: 0.20499 * height),
                      controlPoint1: CGPoint(x: 0.01951 * width, y: 0.33988 * height),
                      controlPoint2: CGPoint(x: 0.0252 * width, y: 0.26979 * height))
        path.addCurve(to: CGPoint(x: 0.50041 * width, y: 0.01173 * height),
                      controlPoint1: CGPoint(x: 0.15081 * width, y: 0.09003 * height),
                      controlPoint2: CGPoint(x: 0.31382 * width, y: 0.01173 * height))
        path.addCurve(to: CGPoint(x: 0.98333 * width, y: 0.36745 * height),
                      controlPoint1: CGPoint(x: 0.76829 * width, y: 0.01173 * height),
                      controlPoint2: CGPoint(x: 0.98333 * width, y: 0.17038 * height))
        path.addCurve(to: CGPoint(x: 0.95528 * width, y: 0.55367 * height),
                      controlPoint1: CGPoint(x: 0.98333 * width, y: 0.41437 * height),
                      controlPoint2: CGPoint(x: 0.96423 * width, y: 0.51378 * height))
        path.addCurve(to: CGPoint(x: 0.91504 * width, y: 0.68299 * height),
                      controlPoint1: CGPoint(x: 0.94513 * width, y: 0.59727 * height),
                      controlPoint2: CGPoint(x: 0.93169 * width, y: 0.64044 * height))
        path.addCurve(to: CGPoint(x: 0.50041 * width, y: 0.98768 * height),
                      controlPoint1: CGPoint(x: 0.83943 * width, y: 0.86188 * height),
                      controlPoint2: CGPoint(x: 0.6622 * width, y: 0.98768 * height))
        path.addCurve(to: CGPoint(x: 0.08537 * width, y: 0.68475 * height),
                      controlPoint1: CGPoint(x: 0.28293 * width, y: 0.98768 * height),
                      controlPoint2: CGPoint(x: 0.12967 * width, y: 0.78387 * height))
        path.addCurve(to: CGPoint(x: 0.04268 * width, y: 0.5522 * height),
                      controlPoint1: CGPoint(x: 0.06463 * width, y: 0.63783 * height),
                      controlPoint2: CGPoint(x: 0.04593 * width, y: 0.56364 * height))
        path.addCurve(to: CGPoint(x: 0.01707 * width, y: 0.36745 * height),
                      controlPoint1: CGPoint(x: 0.0252 * width, y: 0.4824 * height),
                      controlPoint2: CGPoint(x: 0.01179 * width, y: 0.43079 * height))
        path.close()

        return path.cgPath
    }

    private func createProgressPath(rect: CGRect, faceWidth: CGFloat, faceHeight: CGFloat, progress: CGFloat) -> CGPath {
        let path = UIBezierPath()
        let width = rect.size.width
        let height = rect.size.height

        path.move(to: CGPoint(x: 0.01707 * width, y: 0.36745 * height))
        // Add the curves and control points based on the progress value
        // ...

        return path.cgPath
    }
}


import SwiftUI

struct FaceOverlayViewWrapper: UIViewRepresentable {
    @Binding var agentMode: Bool
    @ObservedObject var model: SelfieCaptureViewModel

    func makeUIView(context: Context) -> FaceOverlayViews {
        let faceOverlayView = FaceOverlayViews()
        faceOverlayView.agentMode = agentMode
        faceOverlayView.model = model
        return faceOverlayView
    }

    func updateUIView(_ uiView: FaceOverlayViews, context: Context) {
        uiView.agentMode = agentMode
        uiView.model = model
        uiView.setNeedsDisplay()
    }
}
