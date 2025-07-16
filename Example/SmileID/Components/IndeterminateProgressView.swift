import SmileID
import SwiftUI

struct IndeterminateProgressView: View {
  @State private var width: CGFloat = 0
  @State private var offset: CGFloat = 0
  @Environment(\.isEnabled) private var isEnabled

  var body: some View {
    Rectangle()
      .foregroundColor(.gray.opacity(0.15))
      .readWidth()
      .overlay(
        Rectangle()
          .foregroundColor(SmileID.theme.accent)
          .frame(width: width * 0.26, height: 6)
          .clipShape(Capsule())
          .offset(x: -width * 0.6, y: 0)
          .offset(x: width * 1.2 * offset, y: 0)
          .animation(.default.repeatForever().speed(0.265), value: offset)
          .onAppear {
            withAnimation {
              offset = 1
            }
          }
      )
      .clipShape(Capsule())
      .opacity(isEnabled ? 1 : 0)
      .animation(.default, value: isEnabled)
      .frame(height: 6)
      .onPreferenceChange(WidthPreferenceKey.self) { width in
        self.width = width
      }
  }
}

struct WidthPreferenceKey: PreferenceKey {
  static var defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = max(value, nextValue())
  }
}

private struct ReadWidthModifier: ViewModifier {
  private var sizeView: some View {
    GeometryReader { geometry in
      Color.clear.preference(key: WidthPreferenceKey.self, value: geometry.size.width)
    }
  }

  func body(content: Content) -> some View {
    content.background(sizeView)
  }
}

extension View {
  func readWidth() -> some View {
    modifier(ReadWidthModifier())
  }
}

#Preview {
  IndeterminateProgressView()
    .padding()
}
