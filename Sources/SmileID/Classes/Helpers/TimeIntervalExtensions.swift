import Foundation

extension TimeInterval {
    func milliseconds() -> Int {
        return Int(self * 1000)
    }
}
