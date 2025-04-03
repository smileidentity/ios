import SwiftUI

public struct CancellableNavigationView<Content: View>: View {
    @ViewBuilder let content: () -> Content
    let onCancel: () -> Void

    public init(
        content: @escaping () -> Content,
        onCancel: @escaping () -> Void
    ) {
        self.content = content
        self.onCancel = onCancel
    }

    public var body: some View {
        NavigationView {
            content()
                .navigationBarItems(
                    leading: Button {
                        onCancel()
                    } label: {
                        Text(SmileIDResourcesHelper.localizedString(for: "Action.Cancel"))
                            .foregroundColor(SmileID.theme.accent)
                    }
                )
        }
    }
}
