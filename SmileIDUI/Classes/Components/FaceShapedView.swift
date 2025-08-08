import SwiftUI

struct FaceShapedView: View {
  let borderColor: Color

  init(borderColor: Color = .white) {
    self.borderColor = borderColor
  }

  var body: some View {
    ZStack {
      Color.black.opacity(0.5)

      Circle()
        .stroke(borderColor, lineWidth: 3)
        .aspectRatio(1.0, contentMode: .fit)
        .scaleEffect(0.7)
    }
    .edgesIgnoringSafeArea(.all)
  }
}
