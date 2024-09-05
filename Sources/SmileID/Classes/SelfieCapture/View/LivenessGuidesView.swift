import SwiftUI

struct LivenessGuidesView: View {
    var playAnimation: Bool = false

    @State private var lookRightProgress: CGFloat = 0.0
    @State private var lookLeftProgress: CGFloat = 0.0
    @State private var lookUpProgress: CGFloat = 0.0

    var body: some View {
        ZStack {
            Group {
                // Look Up Guide
                Circle()
                    .trim(from: 0.85, to: 1.0)
                    .rotation(.degrees(-65))
                    .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                    .foregroundColor(.gray.opacity(0.3))
                    .frame(width: 300, height: 300)
                // Look Up Progress
                Circle()
                    .trim(from: 0.85, to: 1.0)
                    .rotation(.degrees(-65))
                    .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                    .foregroundColor(.green)
                    .frame(width: 300, height: 300)
            }
            Group {
                // Look Right Guide
                Circle()
                    .trim(from: 0.85, to: 1.0)
                    .rotation(.degrees(25))
                    .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                    .foregroundColor(.gray.opacity(0.3))
                    .frame(width: 300, height: 300)
                // Look Right Progress
                Circle()
                    .trim(from: 0.85, to: 1.0)
                    .rotation(.degrees(25))
                    .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                    .foregroundColor(.gray.opacity(0.3))
                    .frame(width: 300, height: 300)
            }
            Group {
                // Look Left Guide
                Circle()
                    .trim(from: 0.85, to: 1.0)
                    .rotation(.degrees(210))
                    .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                    .foregroundColor(.gray.opacity(0.3))
                    .frame(width: 300, height: 300)
                // Look Left Progress
                Circle()
                    .trim(from: 0.85, to: 1.0)
                    .rotation(.degrees(210))
                    .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                    .foregroundColor(.gray.opacity(0.3))
                    .frame(width: 300, height: 300)
            }
        }
        .onAppear {
            if playAnimation {}
        }
    }
}

struct TripleArcProgressView: View {
    @State private var progress: CGFloat = 0.5 // Set the initial progress (0.0 to 1.0)

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                .frame(width: 235, height: 235)

            ForEach(0..<3) { index in
                ArcShape(startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 90))
                    .trim(from: 0.0, to: min(progress, 1.0))
                    .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .foregroundColor(.green)
                    .rotationEffect(Angle(degrees: Double(index) * 120))
                    .frame(width: 265, height: 265)
            }
        }
    }
}

struct ArcShape: Shape {
    var startAngle: Angle
    var endAngle: Angle

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        return path
    }
}
