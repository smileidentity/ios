import Foundation
import UIKit
import SwiftUI

extension EnvironmentValues {
    var isPreview: Bool {
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}

extension View {
    var window: UIWindow? {
        return UIApplication
            .shared
            .connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .last { $0.isKeyWindow }
    }
}
