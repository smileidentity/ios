import Foundation

extension String {
    func jobTimestampDate() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
        return dateFormatter.date(from: self)
    }
}
