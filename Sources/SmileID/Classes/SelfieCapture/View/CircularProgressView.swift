import SwiftUI

struct CircularProgressView: View {
    @State private var rotationAngle: Double = 0.0

    var body: some View {
        Image(uiImage: SmileIDResourcesHelper.Loader)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 48, height: 48)
            .rotationEffect(Angle(degrees: rotationAngle))
            .onAppear {
                DispatchQueue.main.async {
                    withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                        rotationAngle = 360
                    }
                }
            }
    }
}
