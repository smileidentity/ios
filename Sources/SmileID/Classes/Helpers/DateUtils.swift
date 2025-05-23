import Foundation

extension Date {
    /// Converts Date to ISO8601 string with millisecond precision in UTC timezone
    /// Format: yyyy-MM-dd'T'HH:mm:ss.SSS'Z' (e.g. 2025-02-03T12:34:56.789Z)
    public func toISO8601WithMilliseconds(
        timezone: TimeZone? = TimeZone(abbreviation: "UTC")
    ) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = timezone
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}
