import SwiftUI

struct LivenessGuidesView: View {
    @Binding var topArcProgress: CGFloat
    @Binding var rightArcProgress: CGFloat
    @Binding var leftArcProgress: CGFloat

    var body: some View {
        ZStack {
            // Top Arc
            ArcProgressView(progress: topArcProgress)
                .rotationEffect(Angle(degrees: 60))
                .opacity(topArcProgress > 0.0 ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.2), value: topArcProgress)

            // Right Arc
            ArcProgressView(progress: rightArcProgress, clockwise: true)
                .rotationEffect(Angle(degrees: -150))
                .opacity(rightArcProgress > 0.0 ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.2), value: rightArcProgress)

            // Left Arc
            ArcProgressView(progress: leftArcProgress)
                .rotationEffect(Angle(degrees: -30))
                .opacity(leftArcProgress > 0.0 ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.2), value: leftArcProgress)
        }
    }
}
