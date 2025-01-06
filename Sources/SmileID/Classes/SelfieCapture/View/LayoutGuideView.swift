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
