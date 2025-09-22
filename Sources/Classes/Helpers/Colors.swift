import SwiftUI

extension Color {
  public init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let alpha: UInt64
    let red: UInt64
    let green: UInt64
    let blue: UInt64
    switch hex.count {
    case 3: // RGB (12-bit)
      (alpha, red, green, blue) =
        (255, (int >> 8) * 17, (int >> 4 & 0xf) * 17, (int & 0xf) * 17)
    case 6: // RGB (24-bit)
      (alpha, red, green, blue) = (255, int >> 16, int >> 8 & 0xff, int & 0xff)
    case 8: // ARGB (32-bit)
      (alpha, red, green, blue) = (int >> 24, int >> 16 & 0xff, int >> 8 & 0xff, int & 0xff)
    default:
      (alpha, red, green, blue) = (1, 1, 1, 0)
    }

    self.init(
      .sRGB,
      red: Double(red) / 255,
      green: Double(green) / 255,
      blue: Double(blue) / 255,
      opacity: Double(alpha) / 255)
  }

  func uiColor() -> UIColor {
    if #available(iOS 14.0, *) {
      return UIColor(self)
    }

    let components = components()
    return UIColor(
      red: components.red,
      green: components.green,
      blue: components.blue,
      alpha: components.alpha)
  }

  func components() -> ColorComponent {
    let scanner = Scanner(
      string: description.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    )
    var hexNumber: UInt64 = 0
    var red: CGFloat = 0.0
    var green: CGFloat = 0.0
    var blue: CGFloat = 0.0
    var alpha: CGFloat = 0.0

    let result = scanner.scanHexInt64(&hexNumber)
    if result {
      red = CGFloat((hexNumber & 0xff00_0000) >> 24) / 255
      green = CGFloat((hexNumber & 0x00ff_0000) >> 16) / 255
      blue = CGFloat((hexNumber & 0x0000_ff00) >> 8) / 255
      alpha = CGFloat(hexNumber & 0x0000_00ff) / 255
    }
    return ColorComponent(
      red: red,
      green: green,
      blue: blue,
      alpha: alpha)
  }
}

struct ColorComponent {
  var red: Double
  var green: Double
  var blue: Double
  var alpha: Double
}
