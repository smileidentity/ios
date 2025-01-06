import SwiftUI

struct LivenessGuidesView: View {
    var currentLivenessTask: LivenessTask
    @Binding var topArcProgress: CGFloat
    @Binding var rightArcProgress: CGFloat
    @Binding var leftArcProgress: CGFloat

    var body: some View {
        ZStack {
            ArcProgressView(position: .top, progress: topArcProgress)
                .rotationEffect(Angle(degrees: 60))
                .opacity(currentLivenessTask == .lookUp ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.2), value: currentLivenessTask)
                .padding(.bottom, 120)

            ArcProgressView(position: .right, progress: rightArcProgress, clockwise: true)
                .rotationEffect(Angle(degrees: -155))
                .opacity(currentLivenessTask == .lookRight ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.2), value: currentLivenessTask)

            ArcProgressView(position: .left, progress: leftArcProgress)
                .rotationEffect(Angle(degrees: -25))
                .opacity(currentLivenessTask == .lookLeft ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.2), value: currentLivenessTask)
        }
    }
}
