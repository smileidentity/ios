import SmileID
import SwiftUI

struct EmptyStateView: View {
    var systemImage: String
    var message: String
    var actionTitle: String
    var action: (() -> Void)?

    init(
        systemImage: String = "exclamationmark.triangle.fill",
        message: String,
        actionTitle: String = "Try Again",
        action: (() -> Void)? = nil
    ) {
        self.systemImage = systemImage
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title)
            Text(message)
            Button { action?() } label: {
                Text(actionTitle)
                    .fontWeight(.semibold)
                    .accentColor(SmileID.theme.accent)
            }
            .padding(.top)
        }
    }
}

#Preview {
    EmptyStateView(message: "No jobs found")
}
