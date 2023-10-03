import UIKit
import SwiftUI

public struct ActivityIndicator: UIViewRepresentable {
    let isAnimating: Bool

    public init(isAnimating: Bool) {
        self.isAnimating = isAnimating
    }

    public func makeUIView(
        context: UIViewRepresentableContext<ActivityIndicator>
    ) -> UIActivityIndicatorView {
        UIActivityIndicatorView(style: .medium)
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
