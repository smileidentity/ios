import Foundation

/// A type representing the state necessary to display a native iOS alert.
struct AlertState: Identifiable {
    let id: UUID
    let title: String
    let message: String?

    init(
        id: UUID = UUID(),
        title: String,
        message: String? = nil
    ) {
        self.id = id
        self.title = title
        self.message = message
    }
}

extension AlertState {
    /// A static property representing an alert state for unauthorized camera access.
    static var cameraUnauthorized: Self {
        AlertState(
            title: SmileIDResourcesHelper.localizedString(for: "Camera.Unauthorized.Title"),
            message: SmileIDResourcesHelper.localizedString(for: "Camera.Unauthorized.Message")
        )
    }
}
