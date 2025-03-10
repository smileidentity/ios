import SmileID
import SwiftUI

struct CancellableNavigationView<Content: View>: View {
    @ViewBuilder let content: () -> Content
    let onCancel: () -> Void

    var body: some View {
        NavigationView {
            content()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            onCancel()
                        } label: {
                            Text(SmileIDResourcesHelper.localizedString(for: "Action.Cancel"))
                                .foregroundColor(SmileID.theme.accent)
                        }
                    }
                }
        }
    }
}
