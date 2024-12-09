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

public extension SmileIdTheme {
    // Not in brand hand book
    var onDark: Color {
        Color(hex: "#F6EDE4")
    }

    var onLight: Color {
        Color(hex: "#2D2B2A")
    }

    // Not in brand handbook
    var backgroundDark: Color {
        Color(hex: "#C0C0A5")
    }

    var backgroundMain: Color {
        Color(hex: "#FFFFFF")
    }

    var backgroundLightest: Color {
        Color(hex: "#F9F0E7")
    }

    // Not in brand handbook
    var backgroundLight: Color {
        Color(hex: "#E2DCD5")
    }

    var success: Color {
        Color(hex: "#2CC05C")
    }

    var error: Color {
        Color(hex: "#91190F")
    }

    var accent: Color {
        Color(hex: "#001096")
    }

    var tertiary: Color {
        Color(hex: "#2D2B2A)")
    }

    // TO-DO: Rename fonts when Kwame comes up with a naming convention
    var header1: Font {
        DMSansFont.bold(with: 24)
    }

    var header2: Font {
        DMSansFont.bold(with: 20)
    }

    var header3: Font {
        DMSansFont.medium(with: 20)
    }

    var header4: Font {
        DMSansFont.medium(with: 16)
    }

    var header5: Font {
        DMSansFont.medium(with: 12)
    }

    var button: Font {
       return header4
    }

    var body: Font {
        DMSansFont.regular(with: 16)
    }
}

// Default Theme
class DefaultTheme: SmileIdTheme {}
