import SwiftUI

public protocol SmileIdTheme {
  // Colors
  var onDark: Color { get }
  var onLight: Color { get }
  var backgroundDark: Color { get }
  var backgroundMain: Color { get }
  var backgroundLight: Color { get }
  var backgroundLightest: Color { get }
  var accent: Color { get }
  var success: Color { get }
  var error: Color { get }
  var tertiary: Color { get }

  // Fonts
  var header1: Font { get }
  var header4: Font { get }
  var header2: Font { get }
  var header5: Font { get }
  var button: Font { get }
  var body: Font { get }
}

extension SmileIdTheme {
  // Not in brand hand book
  public var onDark: Color {
    Color(hex: "#F6EDE4")
  }

  public var onLight: Color {
    Color(hex: "#2D2B2A")
  }

  // Not in brand handbook
  public var backgroundDark: Color {
    Color(hex: "#C0C0A5")
  }

  public var backgroundMain: Color {
    Color(hex: "#FFFFFF")
  }

  public var backgroundLightest: Color {
    Color(hex: "#F9F0E7")
  }

  // Not in brand handbook
  public var backgroundLight: Color {
    Color(hex: "#E2DCD5")
  }

  public var success: Color {
    Color(hex: "#2CC05C")
  }

  public var error: Color {
    Color(hex: "#91190F")
  }

  public var accent: Color {
    Color(hex: "#001096")
  }

  public var tertiary: Color {
    Color(hex: "#2D2B2A)")
  }

  // TO-DO: Rename fonts when Kwame comes up with a naming convention
  public var header1: Font {
    DMSansFont.bold(with: 24)
  }

  public var header2: Font {
    DMSansFont.bold(with: 20)
  }

  public var header3: Font {
    DMSansFont.medium(with: 20)
  }

  public var header4: Font {
    DMSansFont.medium(with: 16)
  }

  public var header5: Font {
    DMSansFont.medium(with: 12)
  }

  public var button: Font {
    header4
  }

  public var body: Font {
    DMSansFont.regular(with: 16)
  }
}

// Default Theme
class DefaultTheme: SmileIdTheme {}
