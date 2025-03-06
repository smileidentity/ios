import SmileID
import SwiftUI

struct SmartSelfieAuthWithUserIdEntry: View {
    let initialUserId: String
    let useStrictMode: Bool
    let delegate: SmartSelfieResultDelegate
    let onDismiss: (() -> Void)

    @State private var userId: String?

    init(
        initialUserId: String,
        useStrictMode: Bool = false,
        delegate: SmartSelfieResultDelegate,
        onDismiss: @escaping () -> Void
    ) {
        self.initialUserId = initialUserId
        self.delegate = delegate
        self.useStrictMode = useStrictMode
        self.onDismiss = onDismiss
    }

    var body: some View {
        if let userId {
            ZStack {
                if useStrictMode {
                    SmileID.smartSelfieAuthenticationScreenEnhanced(
                        config: OrchestratedSelfieCaptureConfig(
                            userId: userId,
                            isEnroll: false
                        ),
                        delegate: delegate,
                        onDismiss: onDismiss
                    )
                } else {
                    SmileID.smartSelfieAuthenticationScreen(
                        config: OrchestratedSelfieCaptureConfig(
                            userId: userId,
                            isEnroll: false,
                            allowAgentMode: true
                        ),
                        delegate: delegate,
                        onDismiss: onDismiss
                    )
                }
            }
            .transition(.move(edge: .trailing))
        } else {
            CancellableNavigationView {
                EnterUserIDView(initialUserId: initialUserId) { userId in
                    withAnimation {
                        self.userId = userId
                    }
                }
            } onCancel: {
                onDismiss()
            }
            .transition(.move(edge: .leading))
        }
    }
}
