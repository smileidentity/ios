import UIKit
import SwiftUI

struct ActivityIndicator: UIViewRepresentable {
    let isAnimating: Bool

    func makeUIView(
        context: UIViewRepresentableContext<ActivityIndicator>
    ) -> UIActivityIndicatorView {
        UIActivityIndicatorView(style: .medium)
    }

    func updateUIView(
        _ uiView: UIActivityIndicatorView,
        context: UIViewRepresentableContext<ActivityIndicator>
    ) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}
