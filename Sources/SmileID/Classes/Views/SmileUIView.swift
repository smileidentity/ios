import SwiftUI

public struct SmileUIView<Content: View>: View {
    @EnvironmentObject var navigation: NavigationHelper
    let content: Content

    init(@ViewBuilder _ content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        NavigationView {
            content
        }
    }
}
