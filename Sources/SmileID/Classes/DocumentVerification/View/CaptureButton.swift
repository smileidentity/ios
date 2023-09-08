import SwiftUI

struct CaptureButton: View {
    var action: (() -> Void)
    var body: some View {
        Button(action: action, label: {
            Image(uiImage: SmileIDResourcesHelper.Capture)
        })
        .frame(width: 70, height: 70, alignment: .center)
    }
}

struct CaptureButton_Previews: PreviewProvider {
    static var previews: some View {
        CaptureButton {}
    }
}

import UIKit

class TransparentCenterView: UIView {

    var transparentRectSize = CGSize(width: 100, height: 100) {
        didSet {
            setNeedsDisplay()
        }
    }
    var borderWidth: CGFloat = 10.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    var borderColor: UIColor = .green {
        didSet {
            setNeedsDisplay()
        }
    }
    var translucentColor: UIColor = .white.withAlphaComponent(0.6)

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.backgroundColor = .clear
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        // Create a path for the full view
        let fullViewPath = UIBezierPath(rect: rect)

        // Calculate the center rectangle's position
        let transparentRectOrigin = CGPoint(
            x: (rect.width - transparentRectSize.width) / 2,
            y: (rect.height - transparentRectSize.height) / 2
        )

        // Create the transparent rectangle path
        let transparentRect = CGRect(origin: transparentRectOrigin, size: transparentRectSize)
        let transparentRectPath = UIBezierPath(roundedRect: transparentRect, cornerRadius: 16)

        // Subtract the transparent rectangle path from the full view path
        fullViewPath.append(transparentRectPath)
        fullViewPath.usesEvenOddFillRule = true

        // Set the translucent color and fill the path
        translucentColor.setFill()
        fullViewPath.fill()

        // Draw the border around the transparent rectangle
        borderColor.setStroke()
        transparentRectPath.lineWidth = borderWidth
        transparentRectPath.stroke()
    }
}


import SwiftUI

struct TransparentRectangleView: UIViewRepresentable {

    @Binding var transparentRectSize: CGSize
    @Binding var borderColor: UIColor


    func makeUIView(context: Context) -> TransparentCenterView {
        let view = TransparentCenterView(frame: .zero)
        view.transparentRectSize = transparentRectSize
        view.borderColor = borderColor
        return view
    }

    func updateUIView(_ uiView: TransparentCenterView, context: Context) {
        // Handle updates if needed
        uiView.transparentRectSize = transparentRectSize
        uiView.borderColor = borderColor
    }
}
