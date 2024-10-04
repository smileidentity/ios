import SwiftUI

struct LivenessGuidesView: View {
    var currentLivenessTask: LivenessTask
    @Binding var topArcProgress: CGFloat
    @Binding var rightArcProgress: CGFloat
    @Binding var leftArcProgress: CGFloat

    var body: some View {
        ZStack {
            // Top Arc
            ArcProgressView(progress: topArcProgress)
                .rotationEffect(Angle(degrees: 60))
                .opacity(currentLivenessTask == .lookUp ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.2), value: currentLivenessTask)

            // Right Arc
            ArcProgressView(progress: rightArcProgress, clockwise: true)
                .rotationEffect(Angle(degrees: -150))
                .opacity(currentLivenessTask == .lookRight ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.2), value: currentLivenessTask)

            // Left Arc
            ArcProgressView(progress: leftArcProgress)
                .rotationEffect(Angle(degrees: -30))
                .opacity(currentLivenessTask == .lookLeft ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.2), value: currentLivenessTask)
        }
    }
}
