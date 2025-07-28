import UIKit

extension UIScreen {
  /// Returns the screen resolution in pixels as a formatted string
  var formattedResolution: String {
    let scale = scale
    let width = Int(bounds.width * scale)
    let height = Int(bounds.height * scale)
    return "\(width) x \(height)"
  }
}
