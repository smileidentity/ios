import Foundation

/// Encapsulates the bundle and tablename of the Localizable.strings file to be used within the SDK
public struct SmileIDLocalizableStrings {
    public var bundle: Bundle
    public var tablename: String

    /// Initializes a SmileIDLocalizableStrings
    /// - Parameters:
    ///   - bundle: The bundle where the localizable string is located. Usually `Bundle.main`
    ///   - tablename: The name of the localizable strings file. Do not include the files `.strings`
    ///   extension
    public init(bundle: Bundle, tablename: String) {
        self.bundle = bundle
        self.tablename = tablename
    }
}
