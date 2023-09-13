import Foundation

/// Encapsulates the bundle and tablename of the Localizeable.strings file to be used within the SDK
public struct SmileIDLocalizableStrings {
    /// The bundle where the localizable string is located
    public var bundle: Bundle
    /// The name of the localizable strings file. Do not include the files `.strings` extension
    public var tablename: String

    public init(bundle: Bundle, tablename: String) {
        self.bundle = bundle
        self.tablename = tablename
    }
}
