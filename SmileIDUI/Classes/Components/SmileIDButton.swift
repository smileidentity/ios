import SwiftUI

public struct SmileIDButton: View {
  var text: String
  var onClick: () -> Void

  init(
    text: String,
    onClick: @escaping () -> Void
  ) {
    self.text = text
    self.onClick = onClick
  }

  public var body: some View {
    Button(action: onClick) {
      Text(text)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(8)
    }
  }
}
