import SwiftUI

enum DMSans: String, CaseIterable {
    case regular = "DMSans-Regular"
    case medium = "DMSans-Medium"
    case bold = "DMSans-Bold"
}

public struct DMSansFont: FontType {
    public static var medium: Font {
        medium(with: SmileIDResourcesHelper.pointSize)
    }

    public static var bold: Font {
        bold(with: SmileIDResourcesHelper.pointSize)
    }

    public static var pointSize: CGFloat {
        SmileIDResourcesHelper.pointSize
    }

    public static func regular(with size: CGFloat) -> Font {
        SmileIDResourcesHelper.loadFontIfNeeded(name: DMSans.regular.rawValue)
        return Font.custom(DMSans.regular.rawValue, size: size)
    }

    public static func medium(with size: CGFloat) -> Font {
        SmileIDResourcesHelper.loadFontIfNeeded(name: DMSans.medium.rawValue)
        return Font.custom(DMSans.medium.rawValue, size: size)
    }

    public static func bold(with size: CGFloat) -> Font {
        SmileIDResourcesHelper.loadFontIfNeeded(name: DMSans.bold.rawValue)
        return Font.custom(DMSans.bold.rawValue, size: size)
    }
}
