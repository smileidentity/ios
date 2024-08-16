import SwiftUI

// the height of the bar
private let height: CGFloat = 4
// how much does the blue part cover the gray part (40%)
private let coverPercentage: CGFloat = 0.4
private let minOffset: CGFloat = -2
private let maxOffset = 1 / coverPercentage * abs(minOffset)

struct InfiniteProgressBar: View {
    @State private var offset = minOffset

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .foregroundColor(SmileID.theme.tertiary.opacity(0.4))
            .frame(height: height)
            .overlay(GeometryReader { geo in
                overlayRect(in: geo.frame(in: .global))
            })
            .clipped()
            .preferredColorScheme(.light)
    }

    private func overlayRect(in rect: CGRect) -> some View {
        let width = rect.width * coverPercentage
        return RoundedRectangle(cornerRadius: 2)
            .foregroundColor(SmileID.theme.accent)
            .frame(width: width)
            .offset(x: width * offset)
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    self.offset = maxOffset
                }
            }
    }
}
