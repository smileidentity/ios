import Foundation

extension Date {
  func jobTimestampFormat() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
    return dateFormatter.string(from: self)
  }
}
