import SwiftUI

struct LayoutGuideView: View {
    let layoutGuideFrame: CGRect

    var body: some View {
        VStack {
          Ellipse()
                .stroke(.blue)
            .frame(width: layoutGuideFrame.width, height: layoutGuideFrame.height)
        }
    }
}

#Preview {
    LayoutGuideView(
        layoutGuideFrame: CGRect(x: 0, y: 0, width: 200, height: 300)
    )
}
