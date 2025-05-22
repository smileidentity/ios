import Foundation

extension Date {
    /// Converts Date to ISO8601 string with millisecond precision in UTC timezone
    /// Format: yyyy-MM-dd'T'HH:mm:ss.SSS'Z' (e.g. 2025-02-03T12:34:56.789Z)
    public func toISO8601WithMilliseconds(
        timezone: TimeZone? = TimeZone(abbreviation: "UTC")
    ) -> String {
        let formatter = DateFormatter()
        /*
        For UTC timezone the pattern adds 'Z' at the end of the string. For any other timezone the
        pattern adds the timezone offset in format +hh:mm or -hh:mm.
         */
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXX"
        formatter.timeZone = timezone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: self)
    }
}
