import Foundation

extension Date {
    static func getCurrentTimeAsHumanReadableTimestamp() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yy, h:mm a"
        return dateFormatter.string(from: Date())
    }
}
