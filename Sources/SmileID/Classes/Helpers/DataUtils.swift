import Foundation

extension Data {
    /// Appends UTF-8 bytes for `string`, asserting in debug if encoding fails.
    mutating func appendUtf8(_ string: String) {
        guard let data = string.data(using: .utf8) else {
            assertionFailure("Failed UTF-8 encoding for: \(string)")
            return
        }
        append(data)
    }
}
