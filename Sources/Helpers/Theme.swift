import UIKit

// Theme Protocol
public protocol Theme {
    var defaultFont: UIFont { get }
    var headerFont: UIFont { get }
    var bodyFont: UIFont { get }
    var captionFont: UIFont { get }

    var primaryColor: UIColor { get }
    var secondaryColor: UIColor { get }
    var textColor: UIColor { get }
    var backgroundColor: UIColor { get }
}

// Default Theme
class DefaultTheme: Theme {
    var defaultFont: UIFont = UIFont.systemFont(ofSize: 14)
    var headerFont: UIFont = UIFont.boldSystemFont(ofSize: 24)
    var bodyFont: UIFont = UIFont.systemFont(ofSize: 16)
    var captionFont: UIFont = UIFont.systemFont(ofSize: 12)

    var primaryColor: UIColor = UIColor(red: 0.2, green: 0.6, blue: 0.8, alpha: 1.0)
    var secondaryColor: UIColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
    var textColor: UIColor = UIColor.black
    var backgroundColor: UIColor = UIColor.white
}
