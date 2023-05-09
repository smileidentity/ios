//
//  File.swift
//  
//
//  Created by Japhet Ndhlovu on 2023/05/09.
//

import SwiftUI

enum Epilogue: String, CaseIterable {
    case bold = "Epilogue-Bold"
    case medium = "Epilogue-Medium"
}


public struct EpilogueFont: FontType {
    
    public static func regular(with size: CGFloat) -> Font {
        //TODO: the project doesn't currently have regular not sure why
        return medium(with: SmileIDResourcesHelper.Font.pointSize)
    }
    
    /// Size of font.
    public static var pointSize: CGFloat {
        return SmileIDResourcesHelper.Font.pointSize
    }
    
    /// Medium font.
    public static var medium: Font {
        return medium(with: SmileIDResourcesHelper.Font.pointSize)
    }
    
    /// Bold font.
    public static var bold: Font {
        return bold(with: SmileIDResourcesHelper.Font.pointSize)
    }
    
    /**
     Medium with size font.
     - Parameter with size: A CGFLoat for the font size.
     - Returns: A UIFont.
     */
    public static func medium(with size: CGFloat) -> Font {
        SmileIDResourcesHelper.Font.loadFontIfNeeded(name: Epilogue.medium.rawValue)
        return Font.custom(Epilogue.medium.rawValue, size: size)
    }
    
    /**
     Bold with size font.
     - Parameter with size: A CGFLoat for the font size.
     - Returns: A UIFont.
     */
    public static func bold(with size: CGFloat) -> Font {
        SmileIDResourcesHelper.Font.loadFontIfNeeded(name: Epilogue.bold.rawValue)
        return Font.custom(Epilogue.bold.rawValue, size: size)
    }
}
