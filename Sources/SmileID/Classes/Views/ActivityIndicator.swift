import UIKit
import SwiftUI

public struct ActivityIndicator: UIViewRepresentable {
    let isAnimating: Bool
    let style: UIActivityIndicatorView.Style

    public init(isAnimating: Bool, style: UIActivityIndicatorView.Style = .medium) {
        self.isAnimating = isAnimating
        self.style = style
    }

    public func makeUIView(
        context: UIViewRepresentableContext<ActivityIndicator>
    ) -> UIActivityIndicatorView {
        UIActivityIndicatorView(style: style)
    }

    public func updateUIView(
        _ uiView: UIActivityIndicatorView,
        context: UIViewRepresentableContext<ActivityIndicator>
    ) {
        if isAnimating {
            uiView.startAnimating()
        } else {
            uiView.stopAnimating()
        }
    }
}
