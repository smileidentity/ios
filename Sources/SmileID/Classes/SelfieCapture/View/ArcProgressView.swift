import SwiftUI

struct ArcProgressView: View {
    // Configuration Properties
    var strokeLineWidth: CGFloat = 12
    var arcSize: CGSize = .init(width: 290, height: 290)
    var progressTrackColor: Color = .gray.opacity(0.3)
    var progressFillColor: Color = .green

    // View Properties
    var progress: CGFloat
    var totalSteps: Int = 10
    var minValue: CGFloat = 0
    var maxValue: CGFloat = 1.0
    var clockwise: Bool = false

    var body: some View {
        ZStack {
            ArcShape(clockwise: clockwise)
                .stroke(
                    style: StrokeStyle(
                        lineWidth: strokeLineWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .foregroundColor(progressTrackColor)
                .frame(width: arcSize.width, height: arcSize.height)
            ArcShape(clockwise: clockwise)
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
    var startAngle: CGFloat = 180
    var endAngle: CGFloat = 120
    var clockwise: Bool = false

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: Angle(degrees: startAngle),
            endAngle: Angle(degrees: clockwise ? endAngle : -endAngle),
            clockwise: clockwise
        )
        return path
    }
}
