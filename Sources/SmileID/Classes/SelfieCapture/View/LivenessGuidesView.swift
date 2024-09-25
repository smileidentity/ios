import SwiftUI

struct LivenessGuidesView: View {
    // Configuration Properties
    var strokeLineWidth: CGFloat = 12
    var arcSize: CGSize = .init(width: 290, height: 290)
    var progressTrackColor: Color = .gray.opacity(0.3)
    var progressFillColor: Color = .green

    @Binding var topArcProgress: CGFloat
    @Binding var rightArcProgress: CGFloat
    @Binding var leftArcProgress: CGFloat

    @State private var topArcOpacity: CGFloat = 1.0
    @State private var rightArcOpacity: CGFloat = 1.0
    @State private var leftArcOpacity: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Top Arc
            ZStack {
                ArcShape(startAngle: Angle(degrees: -30), endAngle: Angle(degrees: 30))
                    .stroke(style: StrokeStyle(lineWidth: strokeLineWidth, lineCap: .round))
                    .foregroundColor(progressTrackColor)
                    .rotationEffect(Angle(degrees: 270))
                    .frame(width: arcSize.width, height: arcSize.height)

                ArcShape(
                    startAngle: Angle(degrees: -30), endAngle: Angle(degrees: -30 + (60 * min(topArcProgress, 1.0)))
                )
                .stroke(style: StrokeStyle(lineWidth: strokeLineWidth, lineCap: .round))
                .foregroundColor(progressFillColor)
                .rotationEffect(Angle(degrees: 270))
                .animation(.linear, value: topArcProgress)
                .frame(width: arcSize.width, height: arcSize.height)
            }
            .opacity(topArcProgress > 0.0 ? 1.0 : 0.0)

            // Right Arc
            ZStack {
                ArcShape(startAngle: Angle(degrees: 30), endAngle: Angle(degrees: -30), clockwise: true)
                    .stroke(style: StrokeStyle(lineWidth: strokeLineWidth, lineCap: .round))
                    .foregroundColor(progressTrackColor)
                    .rotationEffect(Angle(degrees: 0))
                    .frame(width: arcSize.width, height: arcSize.height)

                ArcShape(
                    startAngle: Angle(degrees: 30), endAngle: Angle(degrees: 30 - (60 * min(rightArcProgress, 1.0))),
                    clockwise: true
                )
                .stroke(style: StrokeStyle(lineWidth: strokeLineWidth, lineCap: .round))
                .foregroundColor(progressFillColor)
                .rotationEffect(Angle(degrees: 0))
                .animation(.linear, value: rightArcProgress)
                .frame(width: arcSize.width, height: arcSize.height)
            }
            .opacity(rightArcProgress > 0.0 ? 1.0 : 0.0)

            // Left Arc
            ZStack {
                ArcShape(startAngle: Angle(degrees: -30), endAngle: Angle(degrees: 30))
                    .stroke(style: StrokeStyle(lineWidth: strokeLineWidth, lineCap: .round))
                    .foregroundColor(progressTrackColor)
                    .rotationEffect(Angle(degrees: 180))
                    .frame(width: arcSize.width, height: arcSize.height)

                ArcShape(
                    startAngle: Angle(degrees: -30), endAngle: Angle(degrees: -30 + (60 * min(leftArcProgress, 1.0)))
                )
                .stroke(style: StrokeStyle(lineWidth: strokeLineWidth, lineCap: .round))
                .foregroundColor(progressFillColor)
                .rotationEffect(Angle(degrees: 180))
                .animation(.linear, value: leftArcProgress)
                .frame(width: arcSize.width, height: arcSize.height)
            }
            .opacity(leftArcProgress > 0.0 ? 1.0 : 0.0)
        }
    }
}

struct ArcShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var clockwise: Bool = false

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: clockwise)
        return path
    }
}
