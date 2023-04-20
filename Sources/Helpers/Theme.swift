import SwiftUI

public protocol SmileIdTheme {
    //Colors
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

    //Fonts
    var h1: Font { get }
    var h4: Font { get }
    var h5: Font { get }
    var button: Font { get }
    var body: Font { get }
}

public extension SmileIdTheme {
    //Not in brand hand book
    var onDark: Color {
        Color(hex: "#F6EDE4")
    }

    var onLight: Color {
        Color(hex: "#2D2B2A")
    }

    //Not in brand handbook
    var backgroundDark: Color {
        Color(hex: "#C0C0A5")
    }

    var backgroundMain: Color {
        Color(hex: "#DBDBC4")
    }

    var backgroundLightest: Color {
        Color(hex: "#F9F0E7")
    }

    //Not in brand handbook
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
        Color(hex: "#9394AB")
    }

    // TO-DO: Rename fonts when Kwame comes up with a naming convention
    var h1: Font {
        Font.custom(Epilogue.bold.rawValue, size: 32)
    }

    var h4: Font {
        Font.custom(Epilogue.bold.rawValue, size: 16)
    }

    var h5: Font {
        Font.custom(Epilogue.medium.rawValue, size: 12)
    }

    var button: Font {
        Font.custom(Epilogue.bold.rawValue, size: 20)
    }

    var body: Font {
        Font.custom(Epilogue.medium.rawValue, size: 14)
    }
}

// Default Theme
class DefaultTheme: SmileIdTheme {}
