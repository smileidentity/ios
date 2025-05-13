import UIKit

extension UIScreen {
    /// Returns the screen resolution in pixels as a formatted string
    var formattedResolution: String {
        let scale = self.scale
        let width = Int(self.bounds.width * scale)
        let height = Int(self.bounds.height * scale)
        return "\(width) x \(height)"
    }
}
