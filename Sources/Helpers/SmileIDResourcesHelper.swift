//
//  File.swift
//  
//
//  Created by Japhet Ndhlovu on 2023/05/09.
//

import SwiftUI

public struct SmileIDResourcesHelper {
    /// An internal reference to the images bundle.
    private static var internalBundle: Bundle?
    static let bundleID = "com.smileid.ios.resources"
    
    /**
     A public reference to the images bundle, that aims to detect
     the correct bundle to use.
     */
    public static var bundle: Bundle {
        if nil == SmileIDResourcesHelper.internalBundle {
            
            SmileIDResourcesHelper.internalBundle = Bundle(for: UIView.self)
            let url = SmileIDResourcesHelper.internalBundle!.resourceURL!
            let b = Bundle(url: url.appendingPathComponent(bundleID))
            if let v = b {
                SmileIDResourcesHelper.internalBundle = v
            }
        }
        return SmileIDResourcesHelper.internalBundle!
    }
    
    public static func registerFonts() {
        Epilogue.allCases.forEach {
            Font.loadFontIfNeeded(name: $0.rawValue)
        }
    }
    
    /// Get localized strings
    public static func localizedString(for key: String?,
                                       locale: Locale = .current) -> String {
        
        if let localizedKey = key {
            return NSLocalizedString(localizedKey, bundle: bundle, comment: "")
        }
        return ""//we'll return empty I think this will be easier to notice
    }
    
    /// Get the image by the file name.
    public static func image(_ name: String) -> UIImage? {
        return UIImage(named: name, in: bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
    }
    
    /// SmileID images
    public static var ClearImage = SmileIDResourcesHelper.image("ClearImage")!
    public static var Face = SmileIDResourcesHelper.image("Face")!
    public static var InstructionsHeaderIcon = SmileIDResourcesHelper.image("InstructionsHeaderIcon")!
    public static var Light = SmileIDResourcesHelper.image("Light")!
    public static var SmileEmblem = SmileIDResourcesHelper.image("SmileEmblem")!
    
    
    public struct Font {
        /// Size of font.
        public static let pointSize: CGFloat = 16
        
        /**
         Retrieves the system font with a specified size.
         - Parameter ofSize size: A CGFloat.
         */
        public static func systemFont(ofSize size: CGFloat) -> UIFont {
            return UIFont.systemFont(ofSize: size)
        }
        
        /**
         Retrieves the bold system font with a specified size..
         - Parameter ofSize size: A CGFloat.
         */
        public static func boldSystemFont(ofSize size: CGFloat) -> UIFont {
            return UIFont.boldSystemFont(ofSize: size)
        }
        
        /**
         Retrieves the italic system font with a specified size.
         - Parameter ofSize size: A CGFloat.
         */
        public static func italicSystemFont(ofSize size: CGFloat) -> UIFont {
            return UIFont.italicSystemFont(ofSize: size)
        }
        
        /**
         Loads a given font if needed.
         - Parameter name: A String font name.
         */
        public static func loadFontIfNeeded(name: String) {
            FontLoader.loadFontIfNeeded(name: name)
        }
    }
    
    /// Loads fonts packaged with Material.
    private class FontLoader {
        /// A Dictionary of the fonts already loaded.
        static var loadedFonts: Dictionary<String, String> = Dictionary<String, String>()
        
        /**
         Loads a given font if needed.
         - Parameter fontName: A String font name.
         */
        static func loadFontIfNeeded(name: String) {
            let loadedFont: String? = FontLoader.loadedFonts[name]
            
            if nil == loadedFont && nil == UIFont(name: name, size: 1) {
                FontLoader.loadedFonts[name] = name
                
                let bundle = Bundle(for: FontLoader.self)
                let identifier = bundle.bundleIdentifier
                let fontURL = true == identifier?.hasPrefix("org.cocoapods") ? bundle.url(forResource: name, withExtension: "ttf", subdirectory:bundleID) : bundle.url(forResource: name, withExtension: "ttf")
                
                if let v = fontURL {
                    let data = NSData(contentsOf: v as URL)!
                    let provider = CGDataProvider(data: data)!
                    let font = CGFont(provider)
                    
                    var error: Unmanaged<CFError>?
                    if !CTFontManagerRegisterGraphicsFont(font!, &error) {
                        let errorDescription = CFErrorCopyDescription(error!.takeUnretainedValue())
                        let nsError = error!.takeUnretainedValue() as Any as! Error
                        NSException(name: .internalInconsistencyException, reason: errorDescription as String?, userInfo: [NSUnderlyingErrorKey: nsError as Any]).raise()
                    }
                }
            }
        }
    }
    
}
