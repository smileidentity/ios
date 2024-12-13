import SwiftUI

public class SmileIDResourcesHelper {

    private static var loadedFonts: [String: String] = [String: String]()

    /**
     A public reference to the images bundle, that aims to detect
     the correct bundle to use.
     */

    public static let bundle: Bundle = {
        let candidates = [
            // Bundle should be present here when the package is linked into an App.
            Bundle.main.resourceURL,

            // Bundle should be present here when the package is linked into a framework.
            Bundle(for: SmileIDResourcesHelper.self).resourceURL
        ]

        let bundleName = "SmileID_SmileID"

        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                bundle.load()
                return bundle
            }
        }

        // Return whatever bundle this code is in as a last resort.
        return Bundle(for: SmileIDResourcesHelper.self)
    }()

    public static func registerFonts() {
        Epilogue.allCases.forEach {
            loadFontIfNeeded(name: $0.rawValue)
        }
    }

    /// Get localized, parametrized strings
    public static func localizedString(for key: String, _ args: CVarArg...) -> String {
        String(
            format: NSLocalizedString(
                key,
                tableName: SmileID.localizableStrings?.tablename,
                bundle: SmileID.localizableStrings?.bundle ?? bundle,
                comment: ""
            ),
            arguments: args
        )
    }

    /// Get the image by the file name.
    public static func image(_ name: String) -> UIImage? {
        UIImage(named: name, in: bundle, compatibleWith: nil)?.withRenderingMode(.alwaysOriginal)
    }

    /// SmileID images
    public static var ClearImage = SmileIDResourcesHelper.image("ClearImage")!
    public static var Face = SmileIDResourcesHelper.image("Face")!
    public static var InstructionsHeaderIcon = SmileIDResourcesHelper.image("auth")!
    public static var DocVFrontHero = SmileIDResourcesHelper.image("DocVFrontHero")!
    public static var DocVBackHero = SmileIDResourcesHelper.image("DocVBackHero")!
    public static var Light = SmileIDResourcesHelper.image("Light")!
    public static var SmileEmblem = SmileIDResourcesHelper.image("SmileEmblem")!
    public static var FaceOutline = SmileIDResourcesHelper.image("FaceOutline")!
    public static var DocumentProcessing = SmileIDResourcesHelper.image("DocumentProcessing")!
    public static var Scan = SmileIDResourcesHelper.image("scan")!
    public static var CheckBold = SmileIDResourcesHelper.image("CheckBold")!
    public static var Close = SmileIDResourcesHelper.image("Close")!
    public static var ArrowLeft = SmileIDResourcesHelper.image("ArrowLeft")!
    public static var Capture = SmileIDResourcesHelper.image("Capture")!
    public static var ConsentDenied = SmileIDResourcesHelper.image("ConsentDenied")!
    public static var Biometric = SmileIDResourcesHelper.image("Biometric")!
    public static var ConsentContactDetails = SmileIDResourcesHelper.image("ConsentContactDetails")!
    public static var ConsentDocumentInfo = SmileIDResourcesHelper.image("ConsentDocumentInfo")!
    public static var ConsentPersonalInfo = SmileIDResourcesHelper.image("ConsentPersonalInfo")!
    public static var Loader = SmileIDResourcesHelper.image("Loader")!
    public static var Checkmark = SmileIDResourcesHelper.image("Checkmark")!
    public static var Xmark = SmileIDResourcesHelper.image("Xmark")!

    /// Size of font.
    public static let pointSize: CGFloat = 16

    /**
     Retrieves the system font with a specified size.
     - Parameter size: A CGFloat.
     */
    public static func systemFont(ofSize size: CGFloat) -> UIFont {
        UIFont.systemFont(ofSize: size)
    }

    /**
     Retrieves the bold system font with a specified size..
     - Parameter size: A CGFloat.
     */
    public static func boldSystemFont(ofSize size: CGFloat) -> UIFont {
        UIFont.boldSystemFont(ofSize: size)
    }

    /**
     Retrieves the italic system font with a specified size.
     - Parameter size: A CGFloat.
     */
    public static func italicSystemFont(ofSize size: CGFloat) -> UIFont {
        UIFont.italicSystemFont(ofSize: size)
    }

    /**
     Loads a given font if needed.
     - Parameter name: A String font name.
     */
    static func loadFontIfNeeded(name: String) {
        let loadedFont: String? = loadedFonts[name]

        if nil == loadedFont && nil == UIFont(name: name, size: 1) {
            loadedFonts[name] = name

            let fontURL = bundle.url(forResource: name, withExtension: "ttf")
            if let finalFontUrl = fontURL {
                let data = NSData(contentsOf: finalFontUrl as URL)!
                let provider = CGDataProvider(data: data)!
                let font = CGFont(provider)

                var error: Unmanaged<CFError>?
                if !CTFontManagerRegisterGraphicsFont(font!, &error) {
                    let errorDescription = CFErrorCopyDescription(error!.takeUnretainedValue())
                    if let nsError = error!.takeUnretainedValue() as Any as? Error {
                        NSException(
                            name: .internalInconsistencyException,
                            reason: errorDescription as String?,
                            userInfo: [NSUnderlyingErrorKey: nsError as Any]
                        ).raise()
                    }
                }
            }
        }
    }
}
