import SwiftUI

enum Epilogue: String, CaseIterable {
    case bold = "Epilogue-Bold"
    case medium = "Epilogue-Medium"
}

public struct EpilogueFont: FontType {

    public static func regular(with size: CGFloat) -> Font {
        // TODO: the project doesn't currently have regular not sure why
        return medium(with: SmileIDResourcesHelper.pointSize)
    }

    /// Size of font.
    public static var pointSize: CGFloat {
        return SmileIDResourcesHelper.pointSize
    }

    /// Medium font.
    public static var medium: Font {
        return medium(with: SmileIDResourcesHelper.pointSize)
    }

    /// Bold font.
    public static var bold: Font {
        return bold(with: SmileIDResourcesHelper.pointSize)
    }

    /**
     Medium with size font.
     - Parameter with size: A CGFLoat for the font size.
     - Returns: A UIFont.
     */
    public static func medium(with size: CGFloat) -> Font {
        SmileIDResourcesHelper.loadFontIfNeeded(name: Epilogue.medium.rawValue)
        return Font.custom(Epilogue.medium.rawValue, size: size)
    }

    /**
     Bold with size font.
     - Parameter with size: A CGFLoat for the font size.
     - Returns: A UIFont.
     */
    public static func bold(with size: CGFloat) -> Font {
        SmileIDResourcesHelper.loadFontIfNeeded(name: Epilogue.bold.rawValue)
        return Font.custom(Epilogue.bold.rawValue, size: size)
    }

    public static func mediumUIFont(with size: CGFloat) -> UIFont? {
        SmileIDResourcesHelper.loadFontIfNeeded(name: Epilogue.medium.rawValue)
        return UIFont(name: Epilogue.medium.rawValue, size: size)
    }

    public static func boldUIFont(with size: CGFloat) -> UIFont? {
        SmileIDResourcesHelper.loadFontIfNeeded(name: Epilogue.bold.rawValue)
        return UIFont(name: Epilogue.bold.rawValue, size: size)
    }
}
