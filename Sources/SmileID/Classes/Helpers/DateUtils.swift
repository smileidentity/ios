import Foundation

extension Date {
    /// Converts Date to ISO8601 string with millisecond precision in UTC timezone
    /// Format: yyyy-MM-dd'T'HH:mm:ss.SSS'Z' (e.g. 2025-02-03T12:34:56.789Z)
   public func toISO8601WithMilliseconds() -> String {
       let formatter = DateFormatter()
       formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
       formatter.timeZone = TimeZone(abbreviation: "UTC")
       formatter.locale = Locale(identifier: "en_US_POSIX")
       return formatter.string(from: self)
   }
}
