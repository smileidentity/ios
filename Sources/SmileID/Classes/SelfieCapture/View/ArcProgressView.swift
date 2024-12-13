import SwiftUI

struct ArcProgressView: View {
    // Configuration Properties
    var strokeLineWidth: CGFloat = 12
    var arcSize: CGSize = .init(width: 270, height: 270)
    var progressTrackColor: Color = SmileID.theme.onDark
    var progressFillColor: Color = SmileID.theme.success

    // View Properties
    var position: Position
    var progress: CGFloat
    var totalSteps: Int = 10
    var minValue: CGFloat = 0
    var maxValue: CGFloat = 1.0
    var clockwise: Bool = false

    enum Position { case top, right, left }

    var body: some View {
        ZStack {
            ArcShape(clockwise: clockwise, position: position)
                .stroke(
                    style: StrokeStyle(
                        lineWidth: strokeLineWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .foregroundColor(progressTrackColor)
                .frame(width: arcSize.width, height: arcSize.height)
            ArcShape(clockwise: clockwise, position: position)
                .trim(from: 0.0, to: normalizedProgress)
                .stroke(
                    style: StrokeStyle(
                        lineWidth: strokeLineWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .animation(.linear, value: normalizedProgress)
                .foregroundColor(progressFillColor)
                .frame(width: arcSize.width, height: arcSize.height)
        }
    }

    private var normalizedProgress: CGFloat {
        (progress - minValue) / (maxValue - minValue)
    }

    private var remainingSteps: Int {
        return max(0, totalSteps - Int(progress))
    }
}

struct ArcShape: Shape {
    var clockwise: Bool = false
    var position: ArcProgressView.Position

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Position-dependent values
        let startAngle: CGFloat = 180
        let endAngle: CGFloat
        let radius: CGFloat
        let horizontalOffset: CGFloat
        let verticalOffset: CGFloat

        switch position {
        case .top:
            endAngle = 120
            radius = rect.width / 2
            horizontalOffset = 0
            verticalOffset = 0
        case .right, .left:
            endAngle = 150
            radius = rect.width
            horizontalOffset = -(radius - rect.width / 2)
            verticalOffset = 0
        }

        path.addArc(
            center: CGPoint(
                x: rect.midX - horizontalOffset,
                y: rect.midY - verticalOffset
            ),
            radius: radius,
            startAngle: Angle(degrees: startAngle),
            endAngle: Angle(degrees: clockwise ? endAngle : -endAngle),
            clockwise: clockwise
        )

        return path
    }
}
