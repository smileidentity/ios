import Foundation
import SwiftUI

public func generateJobId() -> String {
    generateId("job-")
}

public func generateUserId() -> String {
    generateId("user-")
}

private func generateId(_ prefix: String) -> String {
    prefix + UUID().uuidString
}

public extension View {
    /// Cuts out the given shape from the view. This is used instead of a ZStack with a shape and a
    /// blendMode of .destinationOut because that causes issues on iOS 14 devices
    func cutout<S: Shape>(_ shape: S) -> some View {
        self.clipShape(
            StackedShape(bottom: Rectangle(), top: shape),
            style: FillStyle(eoFill: true)
        )
    }
}

private struct StackedShape<Bottom: Shape, Top: Shape>: Shape {
    var bottom: Bottom
    var top: Top

    func path(in rect: CGRect) -> Path {
        Path { path in
            path.addPath(bottom.path(in: rect))
            path.addPath(top.path(in: rect))
        }
    }
}

extension String: Error {}
