import SwiftUI

struct DocumentOverlayView: View {
    @State var aspectRatio: CGFloat = 1.66
    @ObservedObject var viewModel: DocumentCaptureViewModel

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                TransparentRectangleView(transparentRectSize: $viewModel.guideSize, borderColor: $viewModel.borderColor)
            }
            .onAppear {
                viewModel.width = geometry.size.width
                viewModel.height = geometry.size.height
            }
        }
    }
}
