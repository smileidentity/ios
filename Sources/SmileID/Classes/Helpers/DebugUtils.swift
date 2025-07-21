import Foundation

/// Lightweight debug logging (compiled out in Release builds)
/// - Parameters:
///   - message: The debug message to log
///   - category: Optional category/tag for the log message (defaults to "SmileID")
func debug(_ message: @autoclosure () -> String, category: String = "SmileID") {
  #if DEBUG
    print("[\(category)] \(message())")
  #endif
}
