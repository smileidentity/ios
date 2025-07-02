import Foundation

extension TimeInterval {
  func milliseconds() -> Int {
    Int(self * 1000)
  }
}
