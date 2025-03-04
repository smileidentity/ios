import Foundation
import UIKit
import Network

public struct Metadata: Codable {
    public var items: [Metadatum]
    public init(items: [Metadatum]) {
        self.items = items
    }

    public static func `default`() -> Metadata {
        Metadata(items: [
            .sdk,
            .sdkVersion,
            .activeLivenessVersion,
            .clientIP,
            .fingerprint,
            .deviceModel,
            .deviceOS,
            .networkConnection
        ])
    }

    public mutating func removeAllOfType<T: Metadatum>(_: T.Type) {
        items.removeAll { $0 is T }
    }
}
