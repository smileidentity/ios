import Foundation

extension TimeInterval {
    func milliseconds() -> String {
        return String(Int(self * 1000))
    }
}
