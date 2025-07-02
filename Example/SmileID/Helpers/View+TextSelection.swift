import SwiftUI

extension View {
  @ViewBuilder
  func enableTextSelection(_ text: String) -> some View {
    if #available(iOS 15.0, *) {
      self
        .textSelection(.enabled)
    } else {
      contextMenu(
        ContextMenu(menuItems: {
          Button("Copy", action: {
            UIPasteboard.general.string = text
          })
        })
      )
    }
  }
}
